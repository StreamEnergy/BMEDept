USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_CP_Load_Segmentation_Data_NE_HUD_Test]    Script Date: 08/25/2014 09:49:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
		
08/15/2014 				Jide Akintoye						Format Stored procedure




**********************************************************************************************/


CREATE PROCEDURE [dbo].[sp_CP_Load_Segmentation_Data_NE_HUD_Test]
AS
    BEGIN

        DELETE  FROM [StreamInternal].[dbo].[CP_Segmentation_Data_Test];

        INSERT  INTO [StreamInternal].[dbo].CP_Segmentation_Data_Test
                ( [CustNo] ,
                  [PremNo] ,
                  [Fraud_NSF] ,
                  [Deposit] ,
                  [Tenure] ,
                  [Avg_Cons_HUD] ,
                  [Customer_is_IA] ,
                  [Dual_Commodity_Elig] ,
                  [On_Dual_Commodity] ,
                  [Enrollment_Source] ,
                  [DataSource] ,
                  [RecordCreatedBy] ,
                  [RecordDate] ,
                  [RecordLastUpdatedBy] ,
                  [RecordLastUpdatedDate]
                )
                SELECT  [CustNo] ,
                        [PremNo] ,
                        NULL AS [Fraud_NSF] ,
                        NULL AS [Deposit] ,
                        NULL AS [Tenure] ,
                        CONVERT(VARCHAR(100) , CAST(( [TotalKWHHistory]
                                                      / NULLIF([NumberOfMonthsHistory] ,
                                                              0) ) AS DECIMAL(38 ,
                                                              4))) AS [Avg_Cons_HUD] ,
                        NULL AS [Customer_is_IA] ,
                        NULL AS [Dual_Commodity_Elig] ,
                        NULL AS [On_Dual_Commodity] ,
                        NULL AS [Enrollment_Source] ,
                        'StreamandStreamMarket' AS [DataSource] ,
                        'sp_CP_Load_Segmentation_Data_HUD_Test' AS [RecordCreatedBy] ,
                        GETDATE() AS [RecordDate] ,
                        'sp_CP_Load_Segmentation_Data_HUD_Test' AS [RecordLastUpdatedBy] ,
                        GETDATE() AS [RecordLastUpdatedDate]
                FROM    [StreamInternal].[dbo].[v_Premise_PLC_HUD]
  
    END



GO


