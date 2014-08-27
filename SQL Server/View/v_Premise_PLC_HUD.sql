USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_Premise_PLC_HUD]    Script Date: 08/26/2014 15:12:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
9/26/2013				MattB								Initial Release v_contract.
															1.) List of latest PLC and HUD data for NE Bucket Report				  
08/26/2014 				Jide Akintoye						Formatted VIEW



**********************************************************************************************/


CREATE VIEW [dbo].[v_Premise_PLC_HUD]
AS
    SELECT 
DISTINCT    p.PremNo ,
            c.CustNo ,
            p.PremType ,
            PLC.CapacityObligation ,
            HUD.TotalKWHHistory ,
            HUD.NumberOfMonthsHistory
    FROM    Stream.dbo.premise p
    LEFT JOIN stream.dbo.Customer c ON p.CustID = c.CustID
    LEFT JOIN ( SELECT
	DISTINCT            s.ESIID ,
                        S.CapacityObligation ,
                        CTR.custid ,
                        ctr.RequestID
                FROM    StreamMarket.dbo.tbl_814_Header H
                INNER JOIN StreamMarket.dbo.tbl_814_Service S ON S.[814_Key] = H.[814_Key]
                INNER JOIN StreamMarket.dbo.tbl_814_Service_Meter M ON M.Service_Key = S.Service_Key
                INNER JOIN stream.dbo.CustomerTransactionRequest CTR ON CTR.transactionnumber = h.TransactionNbr
                                                              AND H.Direction = 1
                INNER JOIN ( SELECT SUBPLC.CustID ,
                                    SUBPLC.EsiId ,
                                    MAX(SUBPLC.RequestID) AS matchrequestid
                             FROM   ( SELECT
			DISTINCT                            s.ESIID ,
                                                S.CapacityObligation ,
                                                CTR.custid ,
                                                ctr.RequestID
                                      FROM      StreamMarket.dbo.tbl_814_Header H
                                      INNER JOIN StreamMarket.dbo.tbl_814_Service S ON S.[814_Key] = H.[814_Key]
                                      INNER JOIN StreamMarket.dbo.tbl_814_Service_Meter M ON M.Service_Key = S.Service_Key
                                      INNER JOIN stream.dbo.CustomerTransactionRequest CTR ON CTR.transactionnumber = h.TransactionNbr
                                                              AND H.Direction = 1
                                      WHERE     s.CapacityObligation IS NOT NULL
                                    ) SUBPLC
                             GROUP BY SUBPLC.CustID ,
                                    SUBPLC.EsiId
                           ) maxling ON maxling.matchrequestid = ctr.RequestID
                WHERE   s.CapacityObligation IS NOT NULL
              ) PLC ON plc.CustID = c.CustID
                       AND plc.EsiId = p.PremNo
    LEFT JOIN ( SELECT 
	DISTINCT            c.CustID ,
                        s.EsiId ,
                        c.RequestID ,
	--h.TransactionNbr,
                        CONVERT(DECIMAL , s.TotalKWHHistory , 2) TotalKWHHistory ,
                        CONVERT(DECIMAL , s.NumberOfMonthsHistory , 2) NumberOfMonthsHistory
                FROM    [StreamMarket].dbo.tbl_814_Service s
                LEFT JOIN [StreamMarket].dbo.tbl_814_Header h ON s.[814_Key] = h.[814_Key]
                LEFT JOIN stream.dbo.CustomerTransactionRequest c ON h.TransactionNbr = c.TransactionNumber
                INNER JOIN ( SELECT SUBHUD.CustID ,
                                    SUBHUD.EsiId ,
                                    MAX(SUBHUD.RequestID) AS matchrequestid
                             FROM   ( SELECT 
			DISTINCT                            c.CustID ,
                                                s.EsiId ,
                                                c.RequestID
                                      FROM      [StreamMarket].dbo.tbl_814_Service s
                                      LEFT JOIN [StreamMarket].dbo.tbl_814_Header h ON s.[814_Key] = h.[814_Key]
                                      LEFT JOIN stream.dbo.CustomerTransactionRequest c ON h.TransactionNbr = c.TransactionNumber
                                      WHERE     s.ActionCode = 'A'
                                                AND h.TransactionSetPurposeCode = 'S'
                                                AND h.ActionCode = 'E'
                                                AND s.NumberOfMonthsHistory IS NOT NULL
                                                AND s.TotalKWHHistory IS NOT NULL
                                    ) SUBHUD
                             GROUP BY SUBHUD.CustID ,
                                    SUBHUD.EsiId
                           ) maxlink ON maxlink.matchrequestid = c.RequestID
                WHERE   s.ActionCode = 'A'
                        AND h.TransactionSetPurposeCode = 'S'
                        AND h.ActionCode = 'E'
                        AND s.NumberOfMonthsHistory IS NOT NULL
                        AND s.TotalKWHHistory IS NOT NULL
              ) HUD ON HUD.CustID = c.CustID
                       AND HUD.EsiId = p.PremNo;


GO


