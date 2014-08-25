USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_Load_TX_Enroll_Drop_Tables]    Script Date: 08/25/2014 12:21:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





/*
============================================================================
************************** Notes/Change Log *******************************
==========================================================================
Date				Author						Description
10/14/2013			Darren Williams				This SP is for the ISTA Aging Report. To run the queries that ISTA gave us.
												Purpose of this SP is for the Daily Billing Report.
												To run the queries that ISTA gave us.
												Initial Release [sp_Load_TX_Enroll_Drop_Tables]
												
08/05/2014 			Jide Akintoye				Format Stored proc script layout


==========================================================================						   
*/


CREATE PROCEDURE [dbo].[sp_Load_TX_Enroll_Drop_Tables]
AS
    BEGIN

-------------------------------
-- Addition 
-------------------------------
        DELETE  FROM StreamInternal.dbo.TX_Enroll_Initial_Meter_Read;

        INSERT  INTO [StreamInternal].[dbo].[TX_Enroll_Initial_Meter_Read]
                ( [LastName]
                , [LastSSN]
                , [BeginServiceDate]
                , [CustNo]
                , [PremNo]
                , [enroll_orig_transaction_id]
                , [EnrollType]
                , [YYYY-MM]
                , DataSource
                , RecordCreatedBy
                , RecordDate
                , RecordLastUpdatedBy
                , RecordLastUpdatedDate
	            )
                SELECT DISTINCT
                        RTRIM(LTRIM(UPPER(t.LastName))) LastName
                      , t.LastSSN
                      , t.BeginServiceDate
                      , t.CustNo
                      , t.PremNo
                      , t.enroll_orig_transaction_id
                      , t.EnrollType
                      , CONVERT(VARCHAR(7) , t.BeginServiceDate , 120) AS 'YYYY-MM'
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate
                FROM    CustomerProfile_TX t 


-------------------------------
-- Drop 
-------------------------------
        DELETE  FROM StreamInternal.dbo.TX_Drop_Final_Meter_Read;

        INSERT  INTO [StreamInternal].[dbo].[TX_Drop_Final_Meter_Read]
                ( [LastName]
                , [LastSSN]
                , [EndServiceDate]
                , [CustNo]
                , [PremNo]
                , [drop_sender_transaction_id]
                , [LossType]
                , [drop_initial_transaction_id]
                , [YYYY-MM]
                , DataSource
                , RecordCreatedBy
                , RecordDate
                , RecordLastUpdatedBy
                , RecordLastUpdatedDate
	            )
                SELECT DISTINCT
                        RTRIM(LTRIM(UPPER(t.LastName))) LastName
                      , t.LastSSN
                      , t.EndServiceDate
                      , t.CustNo
                      , t.PremNo
                      , t.drop_sender_transaction_id
                      , t.LossType
                      , t.drop_initial_transaction_id
                      , CONVERT(VARCHAR(7) , t.EndServiceDate , 120) AS 'YYYY-MM'
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate
                FROM    CustomerProfile_TX t
                WHERE   t.EndServiceDate IS NOT NULL

---------------------------------------------------
--TOS (same customer, diff esiid, within 30 days)
---------------------------------------------------
        DELETE  FROM StreamInternal.dbo.TX_Enroll_TOS;


        INSERT  INTO [StreamInternal].[dbo].[TX_Enroll_TOS]
                ( [LastName]
                , [LastSSN]
                , [BeginServiceDate]
                , [CustNo]
                , [PremNo]
                , [enroll_orig_transaction_id]
                , [EnrollType]
                , [YYYY-MM]
                , [EndServiceDate]
                , [EndCustNo]
                , [LossType]
                , [EndPremNo]
                , [drop_sender_transaction_id]
                , [DateDiff]
                , DataSource
                , RecordCreatedBy
                , RecordDate
                , RecordLastUpdatedBy
                , RecordLastUpdatedDate
	            )
                SELECT DISTINCT
                        s.[LastName]
                      , s.[LastSSN]
                      , s.[BeginServiceDate]
                      , s.[CustNo]
                      , s.[PremNo]
                      , s.[enroll_orig_transaction_id]
                      , s.[EnrollType]
                      , s.[YYYY-MM]
                      , e.EndServiceDate
                      , e.CustNo AS EndCustNo
                      , e.LossType
                      , e.PremNo AS EndPremNo
                      , e.drop_sender_transaction_id
                      , DATEDIFF(DAY , e.EndServiceDate , s.BeginServiceDate) AS 'DateDiff'
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate 
	--into #TOS
                FROM    StreamInternal.dbo.TX_Enroll_Initial_Meter_Read s
                LEFT JOIN StreamInternal.dbo.TX_Drop_Final_Meter_Read e ON s.LastName = e.LastName
                                                              AND s.LastSSN = e.LastSSN
                                                              AND s.PremNo <> e.PremNo
                WHERE   DATEDIFF(DAY , e.EndServiceDate , s.BeginServiceDate) <= 30
                        AND DATEDIFF(DAY , e.EndServiceDate ,
                                     s.BeginServiceDate) >= -30
                ORDER BY DATEDIFF(DAY , e.EndServiceDate , s.BeginServiceDate)


	--select count(distinct t.enroll_orig_transaction_id), t.[YYYY-MM] from #TOS t group by t.[YYYY-MM] order by t.[YYYY-MM]
	--select COUNT(distinct t.enroll_orig_transaction_id),t.LossType from #TOS t group by t.LossType
	--select * from #TOS t where t.LossType = '814_06 Customer Moved (020)' order by t.LastName, t.LastSSN, t.PremNo



---------------------------------------------------
--R1 (Diff Customer, Same ESIID)
---------------------------------------------------
        DELETE  FROM StreamInternal.dbo.[TX_Enroll_Recycle1];


        INSERT  INTO [StreamInternal].[dbo].[TX_Enroll_Recycle1]
                ( [LastName]
                , [LastSSN]
                , [BeginServiceDate]
                , [CustNo]
                , [PremNo]
                , [enroll_orig_transaction_id]
                , [EnrollType]
                , [YYYY-MM]
                , [EndServiceDate]
                , [EndCustNo]
                , [LossType]
                , [EndPremNo]
                , [drop_sender_transaction_id]
                , [DropLastName]
                , [DropLastSSN]
                , [DateDiff]
                , DataSource
                , RecordCreatedBy
                , RecordDate
                , RecordLastUpdatedBy
                , RecordLastUpdatedDate
	            )
                SELECT DISTINCT
                        s.[LastName]
                      , s.[LastSSN]
                      , s.[BeginServiceDate]
                      , s.[CustNo]
                      , s.[PremNo]
                      , s.[enroll_orig_transaction_id]
                      , s.[EnrollType]
                      , s.[YYYY-MM]
                      , e.EndServiceDate
                      , e.CustNo AS EndCustNo
                      , e.LossType
                      , e.PremNo AS EndPremNo
                      , e.drop_sender_transaction_id
                      , e.LastName AS DropLastName
                      , e.LastSSN AS DropLastSSN
                      , DATEDIFF(DAY , e.EndServiceDate , s.BeginServiceDate) AS 'datediff'
                      ,---, t.enroll_orig_transaction_id 
                        'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate 
	--into #R1
                FROM    [StreamInternal].[dbo].[TX_Enroll_Initial_Meter_Read] s
                LEFT JOIN [StreamInternal].[dbo].[TX_Drop_Final_Meter_Read] e ON s.LastName <> e.LastName
                                                              AND s.LastSSN <> e.LastSSN
                                                              AND s.PremNo = e.PremNo
                LEFT JOIN [StreamInternal].[dbo].[TX_Enroll_TOS] t ON s.enroll_orig_transaction_id = t.enroll_orig_transaction_id
                WHERE   t.enroll_orig_transaction_id IS NULL --> make sure we do not grab the same trxn we already classified as TOS above
                        AND DATEDIFF(DAY , e.EndServiceDate ,
                                     s.BeginServiceDate) <= 30
                        AND DATEDIFF(DAY , e.EndServiceDate ,
                                     s.BeginServiceDate) >= -30
                ORDER BY DATEDIFF(DAY , e.EndServiceDate , s.BeginServiceDate)

	--select count(distinct t.enroll_orig_transaction_id), t.[YYYY-MM] from #R1 t group by t.[YYYY-MM] order by t.[YYYY-MM]
	--select COUNT(distinct t.enroll_orig_transaction_id),t.LossType from #R1 t group by t.LossType
	--select top 10 * from #R1


---------------------------------------------------
--R2 (same esiid, enroll within 90days after drop)
---------------------------------------------------
        DELETE  FROM StreamInternal.dbo.[TX_Enroll_Recycle2];


        INSERT  INTO [StreamInternal].[dbo].[TX_Enroll_Recycle2]
                ( [LastName]
                , [LastSSN]
                , [BeginServiceDate]
                , [CustNo]
                , [PremNo]
                , [enroll_orig_transaction_id]
                , [EnrollType]
                , [YYYY-MM]
                , [EndServiceDate]
                , [EndCustNo]
                , [LossType]
                , [EndPremNo]
                , [drop_sender_transaction_id]
                , [DateDiff]
                , DataSource
                , RecordCreatedBy
                , RecordDate
                , RecordLastUpdatedBy
                , RecordLastUpdatedDate
	            )
                SELECT DISTINCT
                        s.[LastName]
                      , s.[LastSSN]
                      , s.[BeginServiceDate]
                      , s.[CustNo]
                      , s.[PremNo]
                      , s.[enroll_orig_transaction_id]
                      , s.[EnrollType]
                      , s.[YYYY-MM]
                      , e.EndServiceDate
                      , e.CustNo AS EndCustNo
                      , e.LossType
                      , e.PremNo AS EndPremNo
                      , e.drop_sender_transaction_id
                      , DATEDIFF(DAY , e.EndServiceDate , s.BeginServiceDate) AS 'datediff'
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate  
	--into #R2
                FROM    [StreamInternal].[dbo].[TX_Enroll_Initial_Meter_Read] s
                LEFT JOIN [StreamInternal].[dbo].[TX_Drop_Final_Meter_Read] e ON s.PremNo = e.PremNo
                LEFT JOIN [StreamInternal].[dbo].[TX_Enroll_TOS] t ON t.enroll_orig_transaction_id = s.enroll_orig_transaction_id
                LEFT JOIN [StreamInternal].[dbo].[TX_Enroll_Recycle1] r ON r.enroll_orig_transaction_id = s.enroll_orig_transaction_id
                WHERE   DATEDIFF(DAY , e.EndServiceDate , s.BeginServiceDate) <= 90
                        AND DATEDIFF(DAY , e.EndServiceDate ,
                                     s.BeginServiceDate) >= 0
                        AND t.enroll_orig_transaction_id IS NULL --> make sure we do not grab the same trxn we already classified as TOS above
                        AND r.enroll_orig_transaction_id IS NULL --> make sure we do not grab the same trxn we already classified as R1 above
                ORDER BY s.PremNo 

	--select count(distinct t.enroll_orig_transaction_id), t.[YYYY-MM] from #R2 t group by t.[YYYY-MM] order by t.[YYYY-MM]
	--select COUNT(distinct t.enroll_orig_transaction_id),t.LossType from #R2 t group by t.LossType
	--select * from #R2

-----------------------------------
--True addition?
-----------------------------------
        DELETE  FROM StreamInternal.dbo.[TX_Enroll_Net];


        INSERT  INTO [StreamInternal].[dbo].[TX_Enroll_Net]
                ( [LastName]
                , [LastSSN]
                , [BeginServiceDate]
                , [CustNo]
                , [PremNo]
                , [enroll_orig_transaction_id]
                , [EnrollType]
                , [YYYY-MM]
                , DataSource
                , RecordCreatedBy
                , RecordDate
                , RecordLastUpdatedBy
                , RecordLastUpdatedDate
	            )
                SELECT DISTINCT
                        s.[LastName]
                      , s.[LastSSN]
                      , s.[BeginServiceDate]
                      , s.[CustNo]
                      , s.[PremNo]
                      , s.[enroll_orig_transaction_id]
                      , s.[EnrollType]
                      , s.[YYYY-MM]
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate        
	-- into #add 
                FROM    [StreamInternal].[dbo].[TX_Enroll_Initial_Meter_Read] s
                LEFT JOIN [StreamInternal].[dbo].[TX_Enroll_TOS] t ON s.enroll_orig_transaction_id = t.enroll_orig_transaction_id
                LEFT JOIN [StreamInternal].[dbo].[TX_Enroll_Recycle1] r ON r.enroll_orig_transaction_id = s.enroll_orig_transaction_id
                LEFT JOIN [StreamInternal].[dbo].[TX_Enroll_Recycle2] rr ON rr.enroll_orig_transaction_id = s.enroll_orig_transaction_id
                WHERE   t.enroll_orig_transaction_id IS NULL
                        AND r.enroll_orig_transaction_id IS NULL
                        AND rr.enroll_orig_transaction_id IS NULL


	--select * from #start s join #TX t on s.enroll_orig_transaction_id = t.enroll_orig_transaction_id where t.PremNo = '10443720003953657'
	--select * from #start s join #TX t on s.enroll_orig_transaction_id = t.enroll_orig_transaction_id where s.LastName = 'ABOAGYE' and s.LastSSN = '8406'

---------------------------
-- EnrollType (1,348,640 row(s) affected) 1330252
---------------------------
        DELETE  FROM StreamInternal.dbo.[TX_Enroll_Summary];


        INSERT  INTO [StreamInternal].[dbo].[TX_Enroll_Summary]
                ( [CustNo]
                , [PremNo]
                , [LastName]
                , [LastSSN]
                , [YYYY-MM]
                , [EnrollType]
                , [enroll_orig_transaction_id]
                , DataSource
                , RecordCreatedBy
                , RecordDate
                , RecordLastUpdatedBy
                , RecordLastUpdatedDate
	            )
                SELECT DISTINCT
                        r.CustNo
                      , r.PremNo
                      , r.LastName
                      , r.LastSSN
                      , r.[YYYY-MM]
                      , 'R1' AS EnrollType
                      , r.enroll_orig_transaction_id
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate  
	--into #EnrollType 
                FROM    [StreamInternal].[dbo].[TX_Enroll_Recycle1] r
                UNION ALL
                SELECT DISTINCT
                        r.CustNo
                      , r.PremNo
                      , r.LastName
                      , r.LastSSN
                      , r.[YYYY-MM]
                      , 'R2' AS EnrollType
                      , r.enroll_orig_transaction_id
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate
                FROM    [StreamInternal].[dbo].[TX_Enroll_Recycle2] r
                UNION ALL
                SELECT DISTINCT
                        r.CustNo
                      , r.PremNo
                      , r.LastName
                      , r.LastSSN
                      , r.[YYYY-MM]
                      , 'TOS' AS EnrollType
                      , r.enroll_orig_transaction_id
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate
                FROM    [StreamInternal].[dbo].[TX_Enroll_TOS] r
                UNION ALL
                SELECT DISTINCT
                        r.CustNo
                      , r.PremNo
                      , r.LastName
                      , r.LastSSN
                      , r.[YYYY-MM]
                      , 'New' AS EnrollType
                      , r.enroll_orig_transaction_id
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate
                FROM    StreamInternal.dbo.[TX_Enroll_Net] r


	--select top 10 * from #EnrollType
	--select COUNT(distinct s.enroll_orig_transaction_id) from #start s
	--select e.[YYYY-MM], e.EnrollType, COUNT(distinct e.enroll_orig_transaction_id) from #EnrollType e
	--group by e.[YYYY-MM], e.EnrollType
	--order by e.[YYYY-MM], e.EnrollType


---------------------------------------------------
--DROP:TOS (same customer, diff esiid, within 30 days)
---------------------------------------------------
        DELETE  FROM StreamInternal.dbo.[TX_Drop_TOS];


        INSERT  INTO [StreamInternal].[dbo].[TX_Drop_TOS]
                ( [BeginServiceDate]
                , [CustNo]
                , [EnrollType]
                , [LastName]
                , [LastSSN]
                , [PremNo]
                , [enroll_orig_transaction_id]
                , [YYYY-MM]
                , [EndServiceDate]
                , [EndCustNo]
                , [LossType]
                , [EndPremNo]
                , [drop_sender_transaction_id]
                , [DateDiff]
                , DataSource
                , RecordCreatedBy
                , RecordDate
                , RecordLastUpdatedBy
                , RecordLastUpdatedDate
	            )
                SELECT DISTINCT
                        s.BeginServiceDate
                      , s.CustNo
                      , s.EnrollType
                      , s.LastName
                      , s.LastSSN
                      , s.PremNo
                      , s.enroll_orig_transaction_id
                      , e.[YYYY-MM]
                      , e.EndServiceDate
                      , e.CustNo AS EndCustNo
                      , e.LossType
                      , e.PremNo AS EndPremNo
                      , e.drop_sender_transaction_id
                      , DATEDIFF(DAY , e.EndServiceDate , s.BeginServiceDate) AS 'DateDiff'
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate  
	--into #D_TOS
                FROM    [StreamInternal].[dbo].[TX_Drop_Final_Meter_Read] e
                LEFT JOIN [StreamInternal].[dbo].[TX_Enroll_Initial_Meter_Read] s ON s.LastName = e.LastName
                                                              AND s.LastSSN = e.LastSSN
                                                              AND s.PremNo <> e.PremNo
                WHERE   DATEDIFF(DAY , e.EndServiceDate , s.BeginServiceDate) <= 30
                        AND DATEDIFF(DAY , e.EndServiceDate ,
                                     s.BeginServiceDate) >= -30
                ORDER BY DATEDIFF(DAY , e.EndServiceDate , s.BeginServiceDate)


	--select count(distinct t.drop_sender_transaction_id), t.[YYYY-MM] from #D_TOS t group by t.[YYYY-MM] order by t.[YYYY-MM]
	--select COUNT(distinct t.drop_sender_transaction_id),t.LossType from #D_TOS t group by t.LossType

---------------------------------------------------
--D1 (Diff Customer, Same ESIID)
---------------------------------------------------
        DELETE  FROM StreamInternal.dbo.[TX_Drop_Recycle1];


        INSERT  INTO [StreamInternal].[dbo].[TX_Drop_Recycle1]
                ( [BeginServiceDate]
                , [CustNo]
                , [EnrollType]
                , [LastName]
                , [LastSSN]
                , [PremNo]
                , [enroll_orig_transaction_id]
                , [YYYY-MM]
                , [EndServiceDate]
                , [EndCustNo]
                , [LossType]
                , [EndPremNo]
                , [drop_sender_transaction_id]
                , [DropLastName]
                , [DropLastSSN]
                , [DateDiff]
                , DataSource
                , RecordCreatedBy
                , RecordDate
                , RecordLastUpdatedBy
                , RecordLastUpdatedDate
	            )
                SELECT DISTINCT
                        s.BeginServiceDate
                      , s.CustNo
                      , s.EnrollType
                      , s.LastName
                      , s.LastSSN
                      , s.PremNo
                      , s.enroll_orig_transaction_id
                      , e.[YYYY-MM]
                      , e.EndServiceDate
                      , e.CustNo AS EndCustNo
                      , e.LossType
                      , e.PremNo AS EndPremNo
                      , e.drop_sender_transaction_id
                      , e.LastName AS DropLastName
                      , e.LastSSN AS DropLastSSN
                      , DATEDIFF(DAY , e.EndServiceDate , s.BeginServiceDate) AS 'datediff'
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate  
	---, t.enroll_orig_transaction_id 
	--into #D1
                FROM    [StreamInternal].[dbo].[TX_Drop_Final_Meter_Read] e
                LEFT JOIN [StreamInternal].[dbo].[TX_Enroll_Initial_Meter_Read] s ON s.LastName <> e.LastName
                                                              AND s.LastSSN <> e.LastSSN
                                                              AND s.PremNo = e.PremNo
                LEFT JOIN [StreamInternal].[dbo].[TX_Drop_TOS] t ON e.drop_sender_transaction_id = t.drop_sender_transaction_id
                WHERE   t.drop_sender_transaction_id IS NULL --> make sure we do not grab the same trxn we already classified as TOS above
                        AND DATEDIFF(DAY , e.EndServiceDate ,
                                     s.BeginServiceDate) <= 30
                        AND DATEDIFF(DAY , e.EndServiceDate ,
                                     s.BeginServiceDate) >= -30
                ORDER BY DATEDIFF(DAY , e.EndServiceDate , s.BeginServiceDate)



	--select count(distinct t.drop_sender_transaction_id), t.[YYYY-MM] from #D1 t group by t.[YYYY-MM] order by t.[YYYY-MM]
	--select COUNT(distinct t.drop_sender_transaction_id),t.LossType from #D1 t group by t.LossType
	--select * from #D1

---------------------------------------------------
--D2 (same esiid, enroll within 90days after drop)
---------------------------------------------------
        DELETE  FROM StreamInternal.dbo.[TX_Drop_Recycle2];


        INSERT  INTO [StreamInternal].[dbo].[TX_Drop_Recycle2]
                ( [BeginServiceDate]
                , [CustNo]
                , [EnrollType]
                , [LastName]
                , [LastSSN]
                , [PremNo]
                , [enroll_orig_transaction_id]
                , [YYYY-MM]
                , [EndServiceDate]
                , [EndCustNo]
                , [LossType]
                , [EndPremNo]
                , [drop_sender_transaction_id]
                , [DateDiff]
                , DataSource
                , RecordCreatedBy
                , RecordDate
                , RecordLastUpdatedBy
                , RecordLastUpdatedDate
	            )
                SELECT DISTINCT
                        s.BeginServiceDate
                      , s.CustNo
                      , s.EnrollType
                      , e.LastName
                      , e.LastSSN
                      , s.PremNo
                      , s.enroll_orig_transaction_id
                      , e.[YYYY-MM]
                      , e.EndServiceDate
                      , e.CustNo AS EndCustNo
                      , e.LossType
                      , e.PremNo AS EndPremNo
                      , e.drop_sender_transaction_id
                      , DATEDIFF(DAY , e.EndServiceDate , s.BeginServiceDate) AS 'datediff'
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate   
	--into #D2
                FROM    [StreamInternal].[dbo].[TX_Drop_Final_Meter_Read] e
                LEFT JOIN [StreamInternal].[dbo].[TX_Enroll_Initial_Meter_Read] s ON s.PremNo = e.PremNo
                LEFT JOIN [StreamInternal].[dbo].[TX_Drop_TOS] t ON t.drop_sender_transaction_id = e.drop_sender_transaction_id
                LEFT JOIN [StreamInternal].[dbo].[TX_Drop_Recycle1] r ON r.drop_sender_transaction_id = e.drop_sender_transaction_id
                WHERE   DATEDIFF(DAY , e.EndServiceDate , s.BeginServiceDate) <= 90
                        AND DATEDIFF(DAY , e.EndServiceDate ,
                                     s.BeginServiceDate) >= 0
                        AND t.drop_sender_transaction_id IS NULL --> make sure we do not grab the same trxn we already classified as TOS above
                        AND r.drop_sender_transaction_id IS NULL --> make sure we do not grab the same trxn we already classified as R1 above
                ORDER BY s.PremNo 


	--select top 10 * from #D2
	--select count(distinct t.drop_sender_transaction_id), t.[YYYY-MM] from #D2 t group by t.[YYYY-MM] order by t.[YYYY-MM]
	--select COUNT(distinct t.drop_sender_transaction_id),t.LossType from #D2 t group by t.LossType
	--select * from #D2

-----------------------------------
--True loss?
-----------------------------------
        DELETE  FROM StreamInternal.dbo.[TX_Drop_Net];


        INSERT  INTO [StreamInternal].[dbo].[TX_Drop_Net]
                ( [LastName]
                , [LastSSN]
                , [EndServiceDate]
                , [CustNo]
                , [PremNo]
                , [drop_sender_transaction_id]
                , [LossType]
                , [drop_initial_transaction_id]
                , [YYYY-MM]
                , DataSource
                , RecordCreatedBy
                , RecordDate
                , RecordLastUpdatedBy
                , RecordLastUpdatedDate
	            )
                SELECT DISTINCT
                        s.[LastName]
                      , s.[LastSSN]
                      , s.[EndServiceDate]
                      , s.[CustNo]
                      , s.[PremNo]
                      , s.[drop_sender_transaction_id]
                      , s.[LossType]
                      , s.[drop_initial_transaction_id]
                      , s.[YYYY-MM]
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate  
	--into #loss 
                FROM    [StreamInternal].[dbo].[TX_Drop_Final_Meter_Read] s
                LEFT JOIN [StreamInternal].[dbo].[TX_Drop_TOS] t ON s.drop_sender_transaction_id = t.drop_sender_transaction_id
                LEFT JOIN [StreamInternal].[dbo].[TX_Drop_Recycle1] r ON r.drop_sender_transaction_id = s.drop_sender_transaction_id
                LEFT JOIN [StreamInternal].[dbo].[TX_Drop_Recycle2] rr ON rr.drop_sender_transaction_id = s.drop_sender_transaction_id
                WHERE   t.drop_sender_transaction_id IS NULL
                        AND r.drop_sender_transaction_id IS NULL
                        AND rr.drop_sender_transaction_id IS NULL
	--and s.PremNo = '1008901016900633820112'


	--select t.* from #start s join #TX t on s.enroll_orig_transaction_id = t.enroll_orig_transaction_id where t.PremNo in ('10443720009333619','10443720009161104','10443720004705123')
	--select * from #start s join #TX t on s.enroll_orig_transaction_id = t.enroll_orig_transaction_id where s.LastName = 'SNYDER' and s.LastSSN = '6913'
	--select COUNT(distinct l.drop_sender_transaction_id), l.LossType from #loss l group by l.LossType 
	--select * from #loss l where l.LossType = '814_24 MVO/MVI (Transfer of Service)'
	--select * from #D_TOS s where s.LastName = 'SNYDER' and s.LastSSN = '6913'
	--select * from #start s where s.LastName = 'SNYDER' and s.LastSSN = '6913'
	--select * from #end s where s.LastName = 'SNYDER' and s.LastSSN = '6913'


---------------------------
-- LossType
---------------------------
        DELETE  FROM StreamInternal.dbo.[TX_Drop_Summary];


        INSERT  INTO [StreamInternal].[dbo].[TX_Drop_Summary]
                ( [EndCustNo]
                , [EndPremNo]
                , [DropLastName]
                , [DropLastSSN]
                , [YYYY-MM]
                , [LossType]
                , [drop_sender_transaction_id]
                , DataSource
                , RecordCreatedBy
                , RecordDate
                , RecordLastUpdatedBy
                , RecordLastUpdatedDate
	            )
                SELECT DISTINCT
                        r.EndCustNo
                      , r.EndPremNo
                      , r.DropLastName
                      , r.DropLastSSN
                      , r.[YYYY-MM]
                      , 'D1' AS LossType
                      , r.drop_sender_transaction_id
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate   
	--into #LossType 
                FROM    [StreamInternal].[dbo].[TX_Drop_Recycle1] r
                UNION ALL
                SELECT DISTINCT
                        r.EndCustNo
                      , r.EndPremNo
                      , r.LastName
                      , r.LastSSN
                      , r.[YYYY-MM]
                      , 'D2' AS LossType
                      , r.drop_sender_transaction_id
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate
                FROM    [StreamInternal].[dbo].[TX_Drop_Recycle2] r
                UNION ALL
                SELECT DISTINCT
                        r.EndCustNo
                      , r.EndPremNo
                      , r.LastName
                      , r.LastSSN
                      , r.[YYYY-MM]
                      , 'DTOS' AS LossType
                      , r.drop_sender_transaction_id
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate
                FROM    [StreamInternal].[dbo].[TX_Drop_TOS] r
                UNION ALL
                SELECT DISTINCT
                        r.CustNo
                      , r.PremNo
                      , r.LastName
                      , r.LastSSN
                      , r.[YYYY-MM]
                      , 'Loss' AS LossType
                      , r.drop_sender_transaction_id
                      , 'TXCustomerProfile' AS DataSource
                      , 'SQL' AS RecordCreatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordDate
                      , 'SP' AS RecordLastUpdatedBy
                      , CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate
                FROM    [StreamInternal].[dbo].[TX_Drop_Net] r

	--select e.[YYYY-MM], e.LossType, COUNT(distinct e.drop_sender_transaction_id) from #LossType e
	--group by e.[YYYY-MM], e.LossType
	--order by e.[YYYY-MM], e.LossType

	--select COUNT(distinct e.drop_sender_transaction_id), e.[YYYY-MM] from #end e where e.[YYYY-MM] like '2012%' group by e.[YYYY-MM] order by e.[YYYY-MM]

	--=====================================
	--final result summary
	--=====================================
	--select * from #EnrollType 
	--select * from #LossType


	----drop table #start
	----drop table #end

	--drop table #TOS
	--drop table #R1
	--drop table #R2
	--drop table #add
	--drop table #EnrollType

	--drop table #D_TOS
	--drop table #D1
	--drop table #D2
	--drop table #loss
	--drop table #LossType

    END





GO


