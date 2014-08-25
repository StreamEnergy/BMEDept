USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_ISTA_NE_Customer_Faultline_Load_Script_Backup]    Script Date: 08/25/2014 12:21:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date				Author						Description
9/22/2013			Steve Nelson				This SP is for the ISTA NE SSIS Report. 
10/11/2013			Darren Williams				Initial Release [sp_ISTA_NE_Customer_Faultline_Load_Script] .
												Purpose of this SP is for the ISTA NE SSIS Report. 
11/14/2013			Darren Williams				Change the join for the "Bring in Customer Info" by adding this:
												"and Premise.PremNo= #stepfinal.ESIID"
01/27/2014			Steve Nelson				Added CustId to Join in "Customer Info" section.
												Added PremNo and CustId to Select and Join in "Determine Current Contract" section.
												Added Distinct to Select and PremNo and CustId to Join in "Bring in Current Product" section.
08/15/2014			Jide Akintoye				Format Stored Procedure




**********************************************************************************************/


CREATE PROCEDURE [dbo].[sp_ISTA_NE_Customer_Faultline_Load_Script_Backup]
AS
    BEGIN

---------------------------------------
--  Delete Temp table of data 
        DELETE  FROM [StreamInternal].[dbo].[tmp_CustomerProfile_ISTA]

--------------------------------
-- get min and max usage (238774 row(s) affected)
--------------------------------
        SELECT  usage.* ,
                finalusage.StatusCode
        INTO    #usage
        FROM    ( SELECT    t.PremID ,
                            t.CustID ,
                            t.ESIID ,
                            t.TransactionType ,
                            t.ActionCode ,
                            MIN(c.DateFrom) MinConsDate ,
                            MAX(c.DateTo) MaxConsDate
                  FROM      Stream.dbo.CustomerTransactionRequest t
                  LEFT OUTER JOIN Stream.dbo.Consumption c ON t.RequestID = c.RequestID
                  WHERE     t.TransactionType = '867'
                            AND t.ActionCode = '03'
                  GROUP BY  t.PremID ,
                            t.CustID ,
                            t.ESIID ,
                            t.TransactionType ,
                            t.ActionCode
                ) usage
        LEFT JOIN --------------------------------
--get Final Usage
--------------------------------
                ( SELECT    t.PremID ,
                            t.CustID ,
                            t.ESIID ,
                            t.TransactionType ,
                            t.ActionCode ,
                            t.StatusCode ,
                            MIN(c.DateFrom) MinConsDate ,
                            MAX(c.DateTo) MaxConsDate
                  FROM      Stream.dbo.CustomerTransactionRequest t
                  LEFT OUTER JOIN Stream.dbo.Consumption c ON t.RequestID = c.RequestID
                  WHERE     t.TransactionType = '867'
                            AND t.ActionCode = '03'
                            AND ( t.StatusCode IS NOT NULL )
                  GROUP BY  t.PremID ,
                            t.CustID ,
                            t.ESIID ,
                            t.TransactionType ,
                            t.ActionCode ,
                            t.StatusCode
                ) finalusage ON usage.PremID = finalusage.PremID
                                AND usage.MaxConsDate = finalusage.MaxConsDate

-------------------------
--get enrollment
-------------------------
        SELECT  t.CustID ,
                t.PremID ,
                t.ESIID ,
                MAX(t.RequestDate) AS EnrollDate
        INTO    #enroll
        FROM    stream.dbo.CustomerTransactionRequest t
        WHERE   t.TransactionType = '814'
                AND t.Direction = '1'
                AND t.ServiceActionCode IN ( 'A' , '7' )
                AND t.ActionCode = 'E'
        GROUP BY t.CustID ,
                t.PremID ,
                t.ESIID

-------------------------
--get reinstatement
-------------------------
        SELECT  t.CustID ,
                t.PremID ,
                t.ESIID ,
                MAX(t.RequestDate) AS ReinstatedDate
        INTO    #reinstate
        FROM    stream.dbo.CustomerTransactionRequest t
        WHERE   t.TransactionType = '814'
                AND t.Direction = '1'
                AND t.ServiceActionCode IN ( 'A' , '7' )
                AND t.ActionCode = 'R'
        GROUP BY t.CustID ,
                t.PremID ,
                t.ESIID

--------------------------
--get esiid change
--------------------------
        SELECT  t.CustID ,
                t.PremID ,
                t.StatusCode ,
                s.EsiId ,
                s.PreviousEsiId , /*s.ServiceType1,*/
                MAX(t.RequestDate) AS ChangeDate
        INTO    #change
        FROM    stream.dbo.CustomerTransactionRequest t
        LEFT JOIN stream.dbo.Premise p ON t.PremID = p.PremID
        LEFT JOIN StreamMarket.dbo.tbl_814_Header h ON h.TransactionNbr = t.TransactionNumber
        LEFT JOIN StreamMarket.dbo.tbl_814_Service s ON h.[814_Key] = s.[814_Key]
        WHERE   t.ActionCode = 'C'
                AND t.StatusCode = 'REF12'
--and s.EsiId in ('211532113400177', '211520659100004')
--and t.CustID = 79825
GROUP BY        t.CustID ,
                t.PremID ,
                t.StatusCode ,
                s.EsiId ,
                s.PreviousEsiId--, s.ServiceType1

-----------------------------
--get drop
-----------------------------
        SELECT  t.CustID ,
                t.PremID ,
                t.ESIID ,
                MAX(t.RequestDate) AS DropDate
        INTO    #drop
        FROM    stream.dbo.CustomerTransactionRequest t
        WHERE   t.TransactionType = '814'
                AND t.Direction = '1'
                AND t.ServiceActionCode IN ( 'A' , '7' )
                AND t.ActionCode = 'D'
        GROUP BY t.CustID ,
                t.PremID ,
                t.ESIID

-------------------------------
--STEP1 = USAGE + ENROLL
-------------------------------
        SELECT  CASE WHEN u.CustID IS NULL THEN e.CustID
                     ELSE u.CustID
                END AS CustID ,
                CASE WHEN u.PremID IS NULL THEN e.PremID
                     ELSE u.PremID
                END AS PremID ,
                CASE WHEN u.ESIID IS NULL THEN e.ESIID
                     ELSE u.ESIID
                END AS ESIID ,
                u.MinConsDate ,
                u.MaxConsDate ,
                u.StatusCode AS FinalUsg ,
                CASE WHEN u.PremID IS NOT NULL THEN 'Y'
                     ELSE 'N'
                END AS 'Usage' ,
                e.EnrollDate
        INTO    #step1
        FROM    #usage u
        FULL OUTER JOIN #enroll e ON u.CustID = e.CustID
                                     AND u.PremID = e.PremID
                                     AND u.ESIID = e.ESIID
        ORDER BY u.CustID

-------------------------------
--STEP2 = STEP1 + REINSTATE
-------------------------------
        SELECT  CASE WHEN a.CustID IS NULL THEN r.CustID
                     ELSE a.CustID
                END AS CustID ,
                CASE WHEN a.PremID IS NULL THEN r.PremID
                     ELSE a.PremID
                END AS PremID ,
                CASE WHEN a.ESIID IS NULL THEN r.ESIID
                     ELSE a.ESIID
                END AS ESIID ,
                a.EnrollDate ,
                a.MinConsDate ,
                a.MaxConsDate ,
                a.FinalUsg ,
                a.Usage ,
                r.ReinstatedDate ,
                CASE WHEN r.ESIID IS NOT NULL THEN 'Y'
                     ELSE 'N'
                END AS 'Reinstatement'
        INTO    #step2
        FROM    #step1 a
        FULL OUTER JOIN #reinstate r ON a.CustID = r.CustID
                                        AND a.PremID = r.PremID
                                        AND a.ESIID = r.ESIID

-------------------------------
--STEP3 = STEP2 + CHANGE
-------------------------------
        SELECT  a.CustID ,
                a.PremID ,
                a.ESIID ,
                a.EnrollDate ,
                a.MinConsDate ,
                a.MaxConsDate ,
                a.FinalUsg ,
                a.Usage ,
                a.ReinstatedDate ,
                a.Reinstatement ,
                ISNULL(c.ChangeDate , c2.ChangeDate) ChangeDate ,
                ISNULL(c.EsiId , c2.EsiId) ChangeNewESIID ,
                ISNULL(c.PreviousEsiId , c2.PreviousEsiId) ChangePreviousEsiId ,
                CASE WHEN c.ChangeDate IS NOT NULL
                          OR c2.ChangeDate IS NOT NULL THEN 'Y'
                     ELSE 'N'
                END AS Change
        INTO    #step3
        FROM    #step2 a
        LEFT JOIN Stream.dbo.Premise p ON a.PremID = p.PremID
        FULL OUTER JOIN #change c ON a.CustID = c.CustID
                                     AND /*a.PremID = c.PremID and*/ a.ESIID = c.EsiId --and substring(p.PremType,1,2) = substring(c.ServiceType1,1,2) --> same commodity
        FULL OUTER JOIN #change c2 ON a.CustID = c2.CustID
                                      AND a.PremID = c2.PremID
                                      AND a.ESIID = c2.PreviousEsiId --and substring(p.PremType,1,2) = substring(c2.ServiceType1,1,2) --> same commodity

-------------------------------
--STEP4 = STEP3 + DROP
-------------------------------
        SELECT  ISNULL(a.CustID , d.CustID) CustID ,
                ISNULL(a.PremID , d.PremID) PremID ,
                ISNULL(a.ESIID , d.ESIID) ESIID ,
                a.EnrollDate ,
                a.MinConsDate ,
                a.MaxConsDate ,
                a.FinalUsg ,
                a.Usage ,
                a.ReinstatedDate ,
                a.Reinstatement ,
                a.Change ,
                a.ChangeDate ,
                a.ChangeNewESIID ,
                a.ChangePreviousEsiId ,
                d.DropDate ,
                CASE WHEN d.DropDate IS NOT NULL THEN 'Y'
                     ELSE 'N'
                END AS 'Drop'
        INTO    #step4
        FROM    #step3 a
        FULL OUTER JOIN #drop d ON a.CustID = d.CustID
                                   AND a.PremID = d.PremID
                                   AND a.ESIID = d.ESIID


---------------------------------------
--start evaluation here
---------------------------------------
        SELECT --DATEDIFF(day,s.DropDate,s.MaxConsDate),
                s.* ,
                ps.PremiseStatusID ,
                ps.Status ,
                l.LDCShortName ,
                p.BeginServiceDate ,
                p.EndServiceDate ,
                CASE WHEN s.EnrollDate IS NULL
                          AND s.MinConsDate IS NOT NULL THEN s.MinConsDate
                     ELSE s.EnrollDate
                END AS BeginFlowDate ,
                CASE 
	--scenario 1: onflow >= 60 days, no usage 
                     WHEN s.MinConsDate IS NULL
                          AND s.EnrollDate < GETDATE() - 60 THEN s.EnrollDate
	--scenario 2
                     WHEN s.MaxConsDate > GETDATE() - 60
                          AND s.DropDate IS NULL
                          AND s.FinalUsg IS NULL THEN NULL 
	--scenario 3
                     WHEN s.DropDate > GETDATE() + 300
                     THEN ISNULL(s.MaxConsDate , s.EnrollDate)
	--scenario 3.1
                     WHEN s.DropDate >= GETDATE() THEN s.DropDate
	--scenario 4
                     WHEN s.MaxConsDate < GETDATE() - 60
                          AND s.DropDate IS NULL THEN s.MaxConsDate
	--scenario 5
                     WHEN s.FinalUsg = 'F'
                          AND ( s.MaxConsDate > s.ReinstatedDate
                                OR s.ReinstatedDate IS NULL
                              ) THEN s.MaxConsDate
	--scenario 6
                     WHEN DATEDIFF(DAY , s.DropDate , s.MaxConsDate) > 30
                          AND s.MaxConsDate > GETDATE() - 60 THEN NULL
	--scenario 7
                     WHEN s.ReinstatedDate > GETDATE() - 70
                          AND ( ( s.MaxConsDate > s.ReinstatedDate )
                                OR DATEDIFF(DAY , s.DropDate , s.MaxConsDate) > 15
                              ) THEN NULL
	--scenario 8 ex ESIID = 'PE000007953361836913'
                     WHEN s.MaxConsDate < GETDATE() - 60
                          AND ( s.MaxConsDate > s.DropDate )
                     THEN s.MaxConsDate
                     ELSE s.DropDate
                END AS EndFlowDate
        INTO    #step5
        FROM    #step4 s
        LEFT JOIN Stream.dbo.Premise p ON s.PremID = p.PremID
                                          AND p.PremNo = s.ESIID
        LEFT JOIN Stream.dbo.PremiseStatus ps ON p.StatusID = ps.PremiseStatusID
        LEFT JOIN Stream.dbo.LDCLookup l ON p.LDCID = l.LDCID
--where 
----STARTDATE
--	DATEDIFF(day,s.EnrollDate,s.MinConsDate) > 10 or
--	DATEDIFF(day,s.EnrollDate,s.MinConsDate) < -10
----ENDDATE
--	--scenario 1: onflow >= 60 days, no usage 
--	--s.MinConsDate is null and s.EnrollDate < GETDATE()-60
--  --scenario 2: 
--  --s.MaxConsDate > GETDATE()-60 and s.DropDate is null and s.FinalUsg is null
--	--scenario 3
--	--s.DropDate >= GETDATE()+300
--	--scenario 3.1
--	--s.DropDate >= GETDATE()
--	--scenario 4
--	--s.MaxConsDate < GETDATE()-60 and s.DropDate IS null 	
--	--scenario 5
--	--s.FinalUsg = 'F' and (s.MaxConsDate > s.ReinstatedDate or s.ReinstatedDate is null)
--  --scenario 6
--  --DATEDIFF(day,s.DropDate, s.MaxConsDate) >30 and s.MaxConsDate > GETDATE()-60
--	--scenario 7
--  --s.ReinstatedDate > GETDATE()-70 and ((s.MaxConsDate > s.ReinstatedDate) or DATEDIFF(day,s.DropDate, s.MaxConsDate)>15)	
--  --scenario 8 ex ESIID = 'PE000007953361836913'
--  --s.MaxConsDate < GETDATE()-60 and (s.MaxConsDate > s.DropDate)
--order by s.EnrollDate
--s.custid in (199284,188720,166035,175061)--(19529,253583,37246,138258,100717)--,205077, 98128, 118408,104709,161550) and
--s.MaxConsDate > s.DropDate and s.MaxConsDate > GETDATE()-60  and s.DropDate < GETDATE()-30 
--DATEDIFF(day,s.DropDate, s.MaxConsDate) >30

-------------------------------
-- flag onflow status
-------------------------------
        SELECT DISTINCT
                f.* ,
                CASE WHEN CONVERT(VARCHAR(10) , GETDATE() , 120) BETWEEN f.BeginFlowDate
                                                              AND
                                                              ISNULL(f.EndFlowDate ,
                                                              '12/31/2999')
                     THEN 'Y'
                     ELSE 'N'
                END AS OnFlow
        INTO    #stepfinal
        FROM    #step5 f

-------------------------------
-- Bring in Customer Info
-------------------------------
        SELECT  Customer.CustID ,
                Customer.CustNo ,
                Premise.PremID ,
                Premise.PremNo ,
                Customer.CustNo + '-' + Premise.PremNo AS LDCNo ,
                PremiseStatus.Status AS PremStatus ,
                CONVERT(DATETIME , #stepfinal.BeginFlowDate) AS BeginServiceDate ,
                CONVERT(DATETIME , #stepfinal.EndFlowDate) AS EndServiceDate ,
                Customer.CustType AS PremiseType ,
                LDCLookup.LDCID ,
                LDCLookup.LDCShortName AS LDCName ,
                NULL AS Market ,
                Premise.PremType AS Commodity ,
                CASE WHEN LDCLookup.LDCShortName = 'PEPCODC' THEN 'DC'
                     ELSE Market.StateAbbr
                END AS State ,
                NULL AS EnrollType ,
                NULL AS LossType ,
                'ISTA' AS DataSource
        INTO    #Customer
        FROM    ( ( ( ( Stream.dbo.LDCLookup LDCLookup
                        LEFT OUTER JOIN StreamInternal.dbo.Market Market ON ( LDCLookup.MarketID = Market.MarketId )
                      )
                      RIGHT OUTER JOIN Stream.dbo.Premise Premise ON ( Premise.LDCID = LDCLookup.LDCID )
                    )
                    LEFT OUTER JOIN Stream.dbo.Customer Customer ON ( Premise.CustID = Customer.CustID )
                  )
                  LEFT OUTER JOIN Stream.dbo.PremiseStatus PremiseStatus ON ( Premise.StatusID = PremiseStatus.PremiseStatusID )
                )
        LEFT OUTER JOIN #stepfinal ON ( Premise.PremID = #stepfinal.PremID
                                        AND Premise.PremNo = #stepfinal.ESIID
                                        AND Premise.CustId = #stepfinal.CustId
                                      )  -- changed join  --  Add CustId to Join (sn 1/27/14)
 

-------------------------------
-- Determine Current Contract
-------------------------------
        SELECT  #Customer.PremID ,
                #Customer.PremNo ,
                #Customer.CustId ,
                MIN(v_Contract.RateDetID) AS RateDetID -- Add PremNo and CustId (sn 1/27/14)
        INTO    #CurrContract
        FROM    #Customer
        LEFT OUTER JOIN StreamInternal.dbo.v_Contract v_Contract ON ( #Customer.PremID = v_Contract.PremID
                                                              AND #Customer.PremNo = v_Contract.PremNo
                                                              AND #Customer.CustId = v_Contract.CustId   --Add PremNo and CustId to join (sn 1/27/14)
                                                              AND ISNULL(#Customer.EndServiceDate ,
                                                              GETDATE()) >= v_Contract.EffectiveDate
                                                              AND ISNULL(#Customer.EndServiceDate ,
                                                              GETDATE()) <= ISNULL(v_Contract.ExpirationDate ,
                                                              GETDATE())
                                                              AND v_Contract.Active = 1
                                                              )
        GROUP BY #Customer.PremID ,
                #Customer.PremNo ,
                #Customer.CustId 

-------------------------------
-- Bring in Current Product
-------------------------------
        INSERT  INTO [StreamInternal].[dbo].[tmp_CustomerProfile_ISTA]
                ( CustID ,
                  CustNo ,
                  PremID ,
                  PremNo ,
                  LDCNo ,
                  PremStatus ,
                  BeginServiceDate ,
                  EndServiceDate ,
                  PremiseType ,
                  LDCID ,
                  LDCName ,
                  Market ,
                  Commodity ,
                  State ,
                  EnrollType ,
                  LossType ,
                  DataSource ,
                  RecordCreatedBy ,
                  RecordDate ,
                  RecordLastUpdatedBy ,
                  RecordLastUpdatedDate ,
                  CurrentProduct
                )
                SELECT
DISTINCT  --Add Distinct (sn 1/27/14)
--top 10
                        #Customer.CustID ,
                        #Customer.CustNo ,
                        #Customer.PremID ,
                        #Customer.PremNo ,
                        #Customer.LDCNo ,
                        #Customer.PremStatus ,
                        #Customer.BeginServiceDate ,
                        #Customer.EndServiceDate ,
                        #Customer.PremiseType ,
                        #Customer.LDCID ,
                        #Customer.LDCName ,
                        #Customer.Market ,
                        #Customer.Commodity ,
                        #Customer.State ,
                        #Customer.EnrollType ,
                        #Customer.LossType ,
                        'ISTA' AS DataSource ,
                        'SSIS' AS RecordCreatedBy ,
                        CONVERT(DATETIME , GETDATE() , 120) AS RecordDate ,
                        'SSIS' AS RecordLastUpdatedBy ,
                        CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate ,
                        v_Contract.RateIndexType AS CurrentProduct
                FROM    #CurrContract
                LEFT OUTER JOIN StreamInternal.dbo.v_Contract v_Contract ON ( #CurrContract.RateDetID = v_Contract.RateDetID )
                                                              AND ( #CurrContract.PremID = v_Contract.PremID )
                RIGHT OUTER JOIN #Customer ON ( #Customer.PremID = #CurrContract.PremID
                                                AND #Customer.PremNo = #CurrContract.PremNo
                                                AND #Customer.CustId = #CurrContract.CustId
                                              )  --Add PremNo and CustId to join (sn 1/27/14)


--INSERT INTO [StreamInternal].[dbo].[tmp_CustomerProfile_ISTA]
--SELECT --#Customer.*

--#Customer.CustID,#Customer.CustNo,
--#Customer.PremID, #Customer.PremNo,
--#Customer.LDCNo, #Customer.PremStatus,
--CONVERT(VARCHAR(10), #Customer.BeginServiceDate, 101) as BeginServiceDate, 
--CONVERT(VARCHAR(10), #Customer.EndServiceDate, 101) as EndServiceDate,
--#Customer.PremiseType, #Customer.LDCID,
--#Customer.LDCName, #Customer.Market, #Customer.Commodity,#Customer.State,
--#Customer.EnrollType, #Customer.LossType,
--'ISTA' As DataSource, 
--'SSIS' as RecordCreatedBy,
--CONVERT(VARCHAR(10), GETDATE(), 101) as RecordDate,
--'SSIS' as RecordLastUpdatedBy,
--	  null as RecordLastUpdatedDate   
--, v_Contract.RateIndexType as CurrentProduct
--FROM #CurrContract
--       LEFT OUTER JOIN StreamInternal.dbo.v_Contract v_Contract ON (#CurrContract.RateDetID = v_Contract.RateDetID) and (#CurrContract.PremID = v_Contract.PremID)
--       RIGHT OUTER JOIN #Customer ON (#Customer.PremID = #CurrContract.PremID)


        DROP TABLE #usage
        DROP TABLE #enroll
        DROP TABLE #reinstate
        DROP TABLE #change
        DROP TABLE #drop
        DROP TABLE #step1
        DROP TABLE #step2
        DROP TABLE #step3
        DROP TABLE #step4
        DROP TABLE #step5
        DROP TABLE #stepfinal
        DROP TABLE #Customer
        DROP TABLE #CurrContract

    END

















GO


