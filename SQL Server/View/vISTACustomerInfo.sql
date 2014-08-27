USE [StreamInternal]
GO

/****** Object:  View [dbo].[vISTACustomerInfo]    Script Date: 08/26/2014 15:15:27 ******/
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

CREATE VIEW [dbo].[vISTACustomerInfo]
AS
    SELECT  s.RateClass ,
            s.LoadProfile ,
            c.CustName ,
            c.FirstName ,
            c.LastName ,
            c.CompanyName ,
            con.PremNo ,
            con.PremID ,
            con.BeginServiceDate ,
            con.EndServiceDate ,
            con.Statusid ,
            con.LDCID ,
            con.EffectiveDate , --'SwitchDate',
            con.ExpirationDate , --'EndDate',
            con.PlanType ,
            con.ProductCode ,
            con.ProductName ,
            s.MeterCycle ,
            con.CreateDate ,
            con.lastupdatedate ,
            s.MeterNumber ,
            con.CustID ,
            con.IndexRate ,
            con.RateID ,
            s.CapacityObligation ,
            s.TransmissionObligation ,
            s.TotalKWHHistory

----****************************************************************** Customer
    FROM    Stream.dbo.Customer C ----****************************************************************** v_Contract
    LEFT JOIN streaminternal.dbo.v_Contract CON ON c.CustID = con.CustID
	 

----****************************************************************** 814 HEADER
---- Inner join into the StreamMarket 814 tables to get 
---- capacity obligation, transmission obligation and total KW history.
    LEFT JOIN ( SELECT	DISTINCT
                        s.ESIID ,
                        m.RateClass ,
                        M.LoadProfile ,
                        M.MeterCycle ,
                        M.MeterNumber ,
                        S.TransmissionObligation ,
                        S.CapacityObligation ,
                        S.TotalKWHHistory ,
                        CTR.custid
                FROM    StreamMarket.dbo.tbl_814_Header H --**************************************************************************** 814 SERVICE
                INNER JOIN StreamMarket.dbo.tbl_814_Service S ON S.[814_Key] = H.[814_Key]
	 
	 --**************************************************************************** 814 SERVICE METER
                INNER JOIN StreamMarket.dbo.tbl_814_Service_Meter M ON M.Service_Key = S.Service_Key
	 
	 --**************************************************************************** CUSTOMER TRANSACTION REQUEST
                INNER JOIN stream.dbo.CustomerTransactionRequest CTR ON CTR.transactionnumber = h.TransactionNbr
                                                              AND H.Direction = 1
                WHERE   TdspDuns NOT IN ( '006917090' , '006917967' )
                        AND s.CapacityObligation IS NOT NULL
              ) S ON S.custid = con.custid

--******************************************************************************************
    WHERE   con.BeginServiceDate <= GETDATE()
  --and (	con.EndServiceDate	> GETDATE() 
		--or 
		--con.EndServiceDate is null
  --    )
            AND ( con.EffectiveDate < con.ExpirationDate
                  OR con.ExpirationDate IS NULL
                )
            AND ( con.EffectiveDate <= GETDATE()
                  OR con.EffectiveDate IS NULL
                )
	
  --and con.LDCID = 22
--  order by 7



GO


