USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_NorthEastInvoices]    Script Date: 09/18/2014 14:18:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
============================================================================================
Date				Author						Description
08/21/2014 			Jide Akintoye				Create NE Invoices


**********************************************************************************************/

ALTER PROCEDURE [dbo].[sp_NorthEastInvoices]
    ( @InvoicePostDate DATETIME
    )
AS
    BEGIN


--/**BeginTest**/
--    DECLARE @InvoicePostDate DATETIME = '09/15/2014'
----SELECT @InvoicePostDate
----SELECT @PostDate

--/**EndTest**/
    --DECLARE @PostDate DATETIME  
    --SET @PostDate = CAST(@InvoicePostDate AS DATE)

/****************************************************
-- Master List
*****************************************************/ 
    --IF OBJECT_ID(N'tempdb..NE_InvLst' , N'U') IS NOT NULL
        DROP TABLE dbo.NorthEast_Invoices;
        SELECT DISTINCT
                Invoice.InvoiceID
              , Invoice.PostDate
              , Invoice.ServiceFrom
              , Invoice.ServiceTo
              , Premise.PremType AS Commodity
              , Customer.CustNo AS [Account No]
              , Premise.PremNo AS [LDC No]
              , Customer.CustName
              , Customer.CustType
              , Customer.BillCycle AS [Bill Group]
              , BillingType.[Description] AS [Bill Type]
              , AccountsReceivableHistory.PrevBal
              , Invoice.InvAmt
              , Address.Addr1
              , Address.City
              , Address.State
              , Address.Zip
              , LDCLookup.LDCShortName
              , Invoice.DueDate
              , SUM(Consumption.BegRead) AS BegRead
              , SUM(Consumption.EndRead) AS EndRead
              , LDCLookup.LDCName
              , Subquery.LastPaidDate
              , Subquery.LastPaidAmt
              , Tax_Misc.TaxAmount
              , Tax_Misc.MiscCharge
              , Energy.GeoCode
              , Energy.EnergyCharge
              , Energy.InvRate
              , Energy.InvDetQty
              , Energy.ProductCode
              , Energy.IndexRate
              , Tax_Misc.TaxRate
        INTO    dbo.NorthEast_Invoices
        FROM    Stream.dbo.Premise Premise
        INNER JOIN Stream.dbo.Address Address ON Premise.AddrID = Address.AddrID
                                                 AND premise.StatusID = 10
        INNER JOIN Stream.dbo.Customer Customer ON Customer.CustID = Premise.CustID
        INNER JOIN Stream.dbo.Invoice Invoice ON Invoice.CustID = Customer.CustID
        LEFT OUTER JOIN Stream.dbo.Consumption Consumption ON Invoice.InvoiceID = Consumption.InvoiceID
        LEFT OUTER JOIN Stream.dbo.AccountsReceivableHistory AccountsReceivableHistory ON Invoice.AcctsRecHistID = AccountsReceivableHistory.AcctsRecHistID
        LEFT OUTER JOIN ( SELECT    PaymentDetail.CustID
                                  , Payment.PaidDate AS LastPaidDate
                                  , SUM(Payment.Amount) AS LastPaidAmt
                          FROM      ( SELECT    PaymentDetail.CustID
                                              , MAX(Payment.PaidDate) AS JDate
                                      FROM      Stream.dbo.PaymentDetail PaymentDetail
                                      INNER JOIN Stream.dbo.Payment Payment ON PaymentDetail.PaymentID = Payment.PaymentID
                                      GROUP BY  PaymentDetail.CustID
                                    ) Subquery
                          INNER JOIN Stream.dbo.PaymentDetail PaymentDetail ON Subquery.CustID = PaymentDetail.CustID
                          INNER JOIN Stream.dbo.Payment Payment ON PaymentDetail.PaymentID = Payment.PaymentID
                                                              AND Subquery.JDate = Payment.PaidDate
                          GROUP BY  Payment.PaidDate
                                  , PaymentDetail.CustID
                        ) Subquery ON Invoice.CustID = Subquery.CustID
        INNER JOIN ( SELECT Invoice.InvoiceID
                          , SUM(CASE WHEN InvoiceDetail.CategoryID = 6
                                     THEN InvoiceDetail.InvDetAmt
                                END) AS TaxAmount
                          , SUM(CASE WHEN InvoiceDetail.CategoryID = 5
                                     THEN InvoiceDetail.InvDetAmt
                                END) AS MiscCharge
                          , SUM(CASE WHEN InvoiceDetail.CategoryID = 6
                                     THEN InvoiceDetail.Rate
                                END)
                            / COUNT(DISTINCT CASE WHEN InvoiceDetail.CategoryID = 1
                                                  THEN InvoiceDetail.MeterID
                                             END) AS TaxRate
                          , COUNT(DISTINCT CASE WHEN InvoiceDetail.CategoryID = 1
                                                THEN InvoiceDetail.MeterID
                                           END) AS MeterCount
                     FROM   Stream.dbo.Invoice Invoice
                     INNER JOIN Stream.dbo.InvoiceDetail InvoiceDetail ON Invoice.InvoiceID = InvoiceDetail.InvoiceID
                     WHERE  CONVERT(VARCHAR , Invoice.PostDate , 101) BETWEEN ( CONVERT(VARCHAR , @InvoicePostDate
                                                              - 15 , 101) )
                                                              AND
                                                              CONVERT(VARCHAR , @InvoicePostDate , 101)
                     GROUP BY Invoice.InvoiceID
                   ) Tax_Misc ON Invoice.InvoiceID = Tax_Misc.InvoiceID
        INNER JOIN ( SELECT Invoice.InvoiceID
                          , InvoiceDetail.GeoCode
                          , SUM(InvoiceDetail.InvDetAmt) AS EnergyCharge
                          , InvoiceDetail.Rate AS InvRate
                          , SUM(InvoiceDetail.InvDetQty) AS InvDetQty
                          , v_Contract.ProductCode
                          , v_Contract.IndexRate
                     FROM   Stream.dbo.InvoiceDetail InvoiceDetail
                     INNER JOIN StreamInternal.dbo.v_Contract v_Contract ON InvoiceDetail.RateDetID = v_Contract.RateDetID
                     INNER JOIN Stream.dbo.Invoice Invoice ON ( Invoice.InvoiceID = InvoiceDetail.InvoiceID )
                     WHERE  InvoiceDetail.CategoryID = 1
                            AND CONVERT(VARCHAR , Invoice.PostDate , 101) BETWEEN ( CONVERT(VARCHAR , @InvoicePostDate
                                                              - 15 , 101) )
                                                              AND
                                                              CONVERT(VARCHAR , @InvoicePostDate , 101)
                     GROUP BY Invoice.InvoiceID
                          , InvoiceDetail.GeoCode
                          , v_Contract.ProductCode
                          , InvoiceDetail.Rate
                          , v_Contract.IndexRate
                   ) Energy ON Invoice.InvoiceID = Energy.InvoiceID
        INNER JOIN Stream.dbo.CustomerAdditionalInfo CustomerAdditionalInfo ON Customer.CustID = CustomerAdditionalInfo.CustID
        INNER JOIN Stream.dbo.BillingType BillingType ON CustomerAdditionalInfo.BillingTypeID = BillingType.BillingTypeID
        INNER JOIN Stream.dbo.LDCLookup LDCLookup ON Premise.LDCID = LDCLookup.LDCID
        INNER JOIN StreamInternal.dbo.Market Market ON LDCLookup.MarketID = Market.MarketId
        WHERE   CONVERT(VARCHAR , Invoice.PostDate , 101) BETWEEN ( CONVERT(VARCHAR , @InvoicePostDate
                                                              - 15 , 101) )
                                                          AND CONVERT(VARCHAR , @InvoicePostDate , 101)
        GROUP BY Invoice.InvoiceID
              , Invoice.PostDate
              , Invoice.ServiceFrom
              , Invoice.ServiceTo
              , Premise.PremType
              , Customer.CustNo
              , Premise.PremNo
              , Customer.CustName
              , Customer.CustType
              , Customer.BillCycle
              , BillingType.[Description]
              , AccountsReceivableHistory.PrevBal
              , Invoice.InvAmt
              , Address.Addr1
              , Address.City
              , Address.State
              , Address.Zip
              , LDCLookup.LDCShortName
              , Invoice.DueDate
              , Subquery.LastPaidDate
              , Subquery.LastPaidAmt
              , LDCLookup.LDCName
              , Tax_Misc.TaxAmount
              , Tax_Misc.MiscCharge
              , Energy.GeoCode
              , Energy.EnergyCharge
              , Energy.InvRate
              , Energy.InvDetQty
              , Energy.ProductCode
              , Energy.IndexRate
              , Tax_Misc.TaxRate;
        
        
        
    END





GO


