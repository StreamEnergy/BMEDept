USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_867HUD]    Script Date: 08/26/2014 13:29:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
9/30/2013				MattB								Pull Useage data from 867 transactions.
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/



CREATE VIEW [dbo].[v_867HUD]
AS
    SELECT  c.CustNo ,
            p.PremNo ,
            c.CustID ,
            p.PremID ,
            ctr.RequestID ,
            NISQ.CompositeUOM ,
            NISQ.ServicePeriodStart ,
            NISQ.ServicePeriodEnd ,
            NISQ.Quantity ,
            ROW_NUMBER() OVER ( PARTITION BY c.CustNo , p.PremNo ,
                                NISQ.CompositeUOM ORDER BY c.CustNo ASC, p.PremNo ASC, NISq.CompositeUOM ASC, NISQ.ServicePeriodEnd DESC ) AS HudRank
    FROM    StreamMarket.dbo.tbl_867_NonIntervalSummary_Qty NISQ
    LEFT JOIN StreamMarket.dbo.tbl_867_NonIntervalSummary NIS ON NISQ.NonIntervalSummary_Key = NIS.NonIntervalSummary_Key
    LEFT JOIN StreamMarket.dbo.tbl_867_Header h ON NIS.[867_Key] = H.[867_Key]
    LEFT JOIN Stream.dbo.CustomerTransactionRequest ctr ON ctr.ReferenceNumber = h.TransactionNbr
    LEFT JOIN Stream.dbo.Customer c ON ctr.CustID = c.CustID
    LEFT JOIN Stream.dbo.Premise p ON p.CustID = c.CustID
    INNER JOIN ( SELECT MAX(ctr.RequestID) AS maxreqid ,
                        ctr.CustID ,
                        ctr.PremID
                 FROM   stream.dbo.CustomerTransactionRequest ctr
                 WHERE  ctr.TransactionType = '867'
                        AND ctr.actioncode = '02'
                 GROUP BY ctr.CustID ,
                        ctr.PremID
               ) maxreq ON maxreq.maxreqid = ctr.RequestID
    WHERE   ctr.TransactionType = '867'
            AND ctr.ActionCode = '02';



GO


