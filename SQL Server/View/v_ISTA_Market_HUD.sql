USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_ISTA_Market_HUD]    Script Date: 08/26/2014 15:08:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
						Eric McCormick						Return market (new customer) detail information stored in the 867
															transactional data within the StreamMarket DB.
															Development Notes:	
															This view is to be used by the v_ISTA_Market_HUD_Summary view.
												
						   
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/



CREATE VIEW [dbo].[v_ISTA_Market_HUD]
AS
    SELECT  X.EsiId AS PremNo ,
            X.TransactionDate ,
            Y.ServicePeriodStart ,
            Y.ServicePeriodEnd ,
            Y.MeterUOM ,
            Y.MeterInterval ,
            Z.Quantity AS Consumption ,
            CASE WHEN DATEDIFF(d , CAST(Y.ServicePeriodStart AS DATE) ,
                               CAST(Y.ServicePeriodEnd AS DATE)) > 0
                 THEN Z.Quantity
                      / CAST(DATEDIFF(d , CAST(Y.ServicePeriodStart AS DATE) ,
                                      CAST(Y.ServicePeriodEnd AS DATE)) AS NUMERIC)
                 ELSE 0
            END AS DailyAvgConsumption
    FROM    StreamMarket.dbo.tbl_867_Header X
    LEFT JOIN StreamMarket.dbo.tbl_867_NonIntervalDetail Y ON X.[867_Key] = Y.[867_Key]
    LEFT JOIN StreamMarket.dbo.tbl_867_NonIntervalDetail_Qty Z ON Y.NonIntervalDetail_Key = Z.NonIntervalDetail_Key
    WHERE   TransactionSetPurposeCode = 52







GO


