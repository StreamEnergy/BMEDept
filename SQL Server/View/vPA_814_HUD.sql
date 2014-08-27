USE [StreamInternal]
GO

/****** Object:  View [dbo].[vPA_814_HUD]    Script Date: 08/26/2014 15:17:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description


08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/

CREATE VIEW [dbo].[vPA_814_HUD]
AS
    SELECT DISTINCT
            c.CustID ,
            s.EsiId ,
            h.TransactionNbr ,
            CONVERT(DECIMAL , s.TotalKWHHistory , 2) TotalKWHHistory ,
            CONVERT(DECIMAL , s.NumberOfMonthsHistory , 2) NumberOfMonthsHistory ,
            CASE WHEN CONVERT(DECIMAL , s.TotalKWHHistory , 2) > 0
                      AND CONVERT(DECIMAL , s.NumberOfMonthsHistory , 2) > 0
                 THEN CONVERT(DECIMAL , ( CONVERT(DECIMAL , s.TotalKWHHistory , 2)
                                          / CONVERT(DECIMAL , s.NumberOfMonthsHistory , 2) ) , 2)
                 ELSE '0'
            END MonthlyAvgKwh
--s.ActionCode, h.TransactionSetPurposeCode, h.ActionCode
--c.*
--into #tmp
    FROM    [StreamMarket].dbo.tbl_814_Service s
    LEFT JOIN [StreamMarket].dbo.tbl_814_Header h ON s.[814_Key] = h.[814_Key]
    LEFT JOIN stream.dbo.CustomerTransactionRequest c ON h.TransactionNbr = c.TransactionNumber
    WHERE   s.ActionCode = 'A'
            AND h.TransactionSetPurposeCode = 'S'
            AND h.ActionCode = 'E'
            AND s.NumberOfMonthsHistory IS NOT NULL
            AND s.TotalKWHHistory IS NOT NULL

GO


