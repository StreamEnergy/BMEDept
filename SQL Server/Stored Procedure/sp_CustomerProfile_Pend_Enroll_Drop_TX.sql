USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_CustomerProfile_Pend_Enroll_Drop_TX]    Script Date: 08/25/2014 09:54:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date				Author								Description
10/14/2013			Darren, Williams					This SP is for the ISTA Aging Report. To run the queries that ISTA gave us.
7/10/2014			Markc								Add loss type					
07/22/2014 			Jide Akintoye						Update Email recipients to 'MeasurementTeam@streamenergy.net'
08/15/2014 			Jide Akintoye						Format Stored procedure
		   
						   
**********************************************************************************************/




CREATE PROCEDURE [dbo].[sp_CustomerProfile_Pend_Enroll_Drop_TX]
AS
    BEGIN

------------------------------------------------------
--get rid of cancelled/unexed pending enrollment trxns
------------------------------------------------------
        SELECT DISTINCT
                ep.*
        INTO    #Enroll_Pend
        FROM    [StreamInternal].[dbo].CustomerProfile_Enroll_Pend_TX ep
        LEFT JOIN StreamInternal.dbo.[CustomerProfile_Enroll_Drop_Cancel_TX] x ON x.originating_transaction_id = ep.enroll_orig_transaction_id
        WHERE   x.originating_transaction_id IS NULL

------------------------------------------------------
--get rid of cancelled/unexed pending drop trxns
------------------------------------------------------
        SELECT DISTINCT
                ep.*
        INTO    #Drop_Pend
        FROM    [StreamInternal].[dbo].CustomerProfile_Drop_Pend_TX ep
        LEFT JOIN StreamInternal.dbo.[CustomerProfile_Enroll_Drop_Cancel_TX] x ON x.originating_transaction_id = ep.drop_orig_transaction_id
        WHERE   x.originating_transaction_id IS NULL



--	Truncate Table [StreamInternal].[dbo].[CustomerProfile_TX]

        SELECT DISTINCT
                ISNULL(t.CustID , ep.CustID) AS CustID ,
                ISNULL(t.CustNo , ep.CustNo) AS CustNo ,
                ISNULL(t.[FirstName] , ep.[FirstName]) AS FirstName ,
                ISNULL(t.[LastName] , ep.[LastName]) AS LastName ,
                ISNULL(t.[LastSSN] , ep.[LastSSN]) AS LastSSN ,
                ISNULL(t.[PremID] , ep.[PremID]) AS [PremID] ,
                ISNULL(t.PremNo , ep.PremNo) AS PremNo ,
                ISNULL(t.[PremStatus] , ep.[PremStatus]) AS PremStatus ,
                ISNULL(t.BeginServiceDate , ep.BeginServiceDate) AS BeginServiceDate ,
                t.EndServiceDate ,
                ISNULL(t.[PremiseType] , ep.[PremiseType]) AS PremiseType ,
                ISNULL(t.[LDCNo] , ep.CustNo + '-' + ep.PremNo) AS LDCNo ,
                ISNULL(t.[LDCID] , ep.[LDCID]) AS LDCID ,
                ISNULL(t.[LDCName] , ep.[LDCName]) AS LDCName ,
                ISNULL(t.[Market] , ep.[Market]) AS Market ,
                ISNULL(t.[Commodity] , ep.[Commodity]) AS Commodity ,
                ISNULL(t.[State] , ep.[State]) AS State ,
                ISNULL(t.[EnrollType] , ep.[EnrollType]) AS EnrollType ,
                t.LossType ,
                ISNULL(t.enroll_orig_transaction_id ,
                       ep.enroll_orig_transaction_id) AS enroll_orig_transaction_id ,
                t.[drop_initial_transaction_id] AS [drop_initial_transaction_id] ,
                t.[drop_sender_transaction_id] AS [drop_sender_transaction_id] ,
                t.[drop_orig_transaction_id] AS [drop_orig_transaction_id] ,
                ISNULL(t.[CurrentProduct] , ep.[CurrentProduct]) AS CurrentProduct ,
                CASE WHEN ep.DataSource IS NULL THEN 'CIS1'
                     ELSE ep.DataSource
                END AS DataSource ,
                CASE WHEN ep.RecordCreatedBy IS NULL THEN 'TX Counts_SSIS.qvw'
                     ELSE ep.RecordCreatedBy
                END AS RecordCreatedBy ,
                CASE WHEN ep.RecordDate IS NULL
                     THEN ( SELECT  MIN(RecordDate)
                            FROM    [StreamInternal].[dbo].CustomerProfile_TX
                            WHERE   [DataSource] = 'CIS1'
                          )
                     ELSE ep.RecordDate
                END AS RecordDate ,
                CASE WHEN ep.RecordLastUpdatedBy IS NULL
                     THEN 'SSIS_AllData.dtsx'
                     ELSE ep.RecordLastUpdatedBy
                END AS RecordLastUpdatedBy ,
                CASE WHEN ep.RecordLastUpdatedDate IS NULL THEN GETDATE()
                     ELSE ep.RecordLastUpdatedDate
                END AS RecordLastUpdatedDate
        INTO    #enroll
        FROM    [StreamInternal].[dbo].CustomerProfile_TX t
        FULL OUTER JOIN #Enroll_Pend ep ON --t.CustNo = ep.custno and ep.PremNo = t.PremNo and 
		t.enroll_orig_transaction_id = ep.enroll_orig_transaction_id

--select * from #enroll (1538276 row(s) affected) (1538233 row(s) affected)
-- drop table #enroll
--select * from #enroll e where e.PremNo = '1008901023817672000106'
--select * from [CustomerProfile_Enroll_Drop_Cancel_TX_Test] t where t.esiid = '1008901023817672000106'

        BEGIN TRY

            BEGIN TRANSACTION tx

            TRUNCATE TABLE [StreamInternal].[dbo].[CustomerProfile_TX]

            INSERT  INTO [StreamInternal].[dbo].[CustomerProfile_TX]
                    ( [CustID] ,
                      [CustNo] ,
                      [FirstName] ,
                      [LastName] ,
                      [LastSSN] ,
                      [PremID] ,
                      [PremNo] ,
                      [PremStatus] ,
                      [BeginServiceDate] ,
                      [EndServiceDate] ,
                      [PremiseType] ,
                      [LDCNo] ,
                      [LDCID] ,
                      [LDCName] ,
                      [Market] ,
                      [Commodity] ,
                      [State] ,
                      [EnrollType] ,
                      [LossType] ,
                      [enroll_orig_transaction_id] ,
                      [drop_initial_transaction_id] ,
                      [drop_sender_transaction_id] ,
                      [drop_orig_transaction_id] ,
                      [CurrentProduct] ,
                      DataSource ,
                      RecordCreatedBy ,
                      RecordDate ,
                      RecordLastUpdatedBy ,
                      RecordLastUpdatedDate
                    )

--(1543642 row(s) affected)
                    SELECT DISTINCT
                            ep.CustID ,
                            ep.CustNo ,
                            ep.[FirstName] ,
                            ep.[LastName] ,
                            ep.[LastSSN] ,
                            ep.[PremID] ,
                            ep.PremNo ,
                            ep.[PremStatus] ,
                            ep.BeginServiceDate ,
                            ISNULL(ep.EndServiceDate , d.EndServiceDate) AS EndServiceDate ,
                            ep.[PremiseType] ,
                            ep.[LDCNo] ,
                            ep.[LDCID] ,
                            ep.[LDCName] ,
                            ep.[Market] ,
                            ep.[Commodity] ,
                            ep.[State] ,
                            ep.[EnrollType] ,
                            ep.LossType ,
                            ep.enroll_orig_transaction_id ,
                            ISNULL(ep.[drop_initial_transaction_id] ,
                                   d.[drop_initial_transaction_id]) AS [drop_initial_transaction_id] ,
                            ISNULL(ep.[drop_sender_transaction_id] ,
                                   d.[drop_sender_transaction_id]) AS [drop_sender_transaction_id] ,
                            ISNULL(ep.[drop_orig_transaction_id] ,
                                   d.[drop_orig_transaction_id]) AS [drop_orig_transaction_id] ,
                            ep.[CurrentProduct] ,
                            CASE WHEN ep.DataSource IS NULL THEN 'CIS1'
                                 ELSE ep.DataSource
                            END AS DataSource ,
                            CASE WHEN ep.RecordCreatedBy IS NULL
                                 THEN 'TX Counts_SSIS.qvw'
                                 ELSE ep.RecordCreatedBy
                            END AS RecordCreatedBy ,
                            CASE WHEN ep.RecordDate IS NULL
                                 THEN ( SELECT  MIN(RecordDate)
                                        FROM    [StreamInternal].[dbo].CustomerProfile_TX
                                        WHERE   [DataSource] = 'CIS1'
                                      )
                                 ELSE ep.RecordDate
                            END AS RecordDate ,
                            CASE WHEN ep.RecordLastUpdatedBy IS NULL
                                 THEN 'SSIS_AllData.dtsx'
                                 ELSE ep.RecordLastUpdatedBy
                            END AS RecordLastUpdatedBy ,
                            CASE WHEN ep.RecordLastUpdatedDate IS NULL
                                 THEN GETDATE()
                                 ELSE ep.RecordLastUpdatedDate
                            END AS RecordLastUpdatedDate
                    FROM    #enroll ep
                    LEFT JOIN #Drop_Pend d ON ep.CustNo = d.custno
                                              AND ep.PremNo = d.PremNo
  
      
            IF @@TRANCOUNT > 0
                BEGIN --SUCCESS, nothing failed, now I can commit!!
                    COMMIT TRANSACTION tx;    -- now everything is committed
                END
      --SET @IsError = @@ERROR
      
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                BEGIN
                    ROLLBACK TRANSACTION tx;
                    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'SMTPRELAY01' ,
                        @from_address = 'SSIS_AllData@streamenergy.net' ,
                        @recipients = 'MeasurementTeam@streamenergy.net' ,
			--'darren.williams@streamenergy.net;steve.nelson@streamenergy.net;mark.cheng@streamenergy.net;matt.baker@streamenergy.net'
                        @subject = 'Error in sp_Customer_Profile_Load_CIS1_TX_Pend_Test' ,
                        @body = 'There was error on insert data into CustomerProfile in sp_Customer_Profile_Load_CIS1_TX_Pend_Test' ,
                        @body_format = 'HTML';        
                END

	--SELECT @IsError = 1, @ErrorMessage = 'Exception message: ' +  Cast (Error_Message() as varchar)  + ';'
	--SELECT @ErrorMessage = 'FAILED - second insert did not populate'
        
        END CATCH;    

        DROP TABLE #enroll    
        DROP TABLE #Enroll_Pend   
        DROP TABLE #Drop_Pend   
      
    END


















GO


