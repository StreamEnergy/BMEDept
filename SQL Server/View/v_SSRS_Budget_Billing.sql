USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_SSRS_Budget_Billing]    Script Date: 08/26/2014 15:13:52 ******/
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

ALTER VIEW [dbo].[v_SSRS_Budget_Billing]
AS
    SELECT
  DISTINCT  Customer.CustNo ,
            InvoiceDetail.MeterID ,
            Invoice.InvoiceID ,
            Invoice.InvDate ,
            Invoice.InvAmt ,
            AccountsReceivable.PaymentPlanAmount ,
            Invoice.TotalDetailAmount - Invoice.InvAmt AS TrueUpAmountDue ,
            CASE WHEN Customer.CustStatus = 'A' THEN 'Active'
                 WHEN Customer.CustStatus = 'I' THEN 'Inactive'
                 ELSE Customer.CustStatus
            END AS CustomerStatus ,
            PremiseStatus.Status AS PremiseStatus ,
            Market.StateAbbr ,
            LDCLookup.LDCShortName ,
            Customer.CustType
    FROM    ( ( ( ( ( ( Stream.dbo.Customer Customer
                        INNER JOIN Stream.dbo.Invoice Invoice ON ( Customer.CustID = Invoice.CustID )
                      )
                      INNER JOIN Stream.dbo.AccountsReceivable AccountsReceivable ON ( Customer.AcctsRecID = AccountsReceivable.AcctsRecID )
                    )
                    LEFT OUTER JOIN Stream.dbo.InvoiceDetail InvoiceDetail ON ( Invoice.InvoiceID = InvoiceDetail.InvoiceID )
                  )
                  LEFT OUTER JOIN Stream.dbo.Premise Premise ON ( InvoiceDetail.PremID = Premise.PremID )
                )
                LEFT OUTER JOIN Stream.dbo.LDCLookup LDCLookup ON ( Premise.LDCID = LDCLookup.LDCID )
              )
              LEFT OUTER JOIN StreamInternal.dbo.Market Market ON ( LDCLookup.MarketID = Market.MarketId )
            )
    LEFT OUTER JOIN Stream.dbo.PremiseStatus PremiseStatus ON ( Premise.StatusID = PremiseStatus.PremiseStatusID )
    WHERE   ( AccountsReceivable.PrePaymentFlag = 0 )
            AND ( Invoice.PaymentPlanFlag = 1 )
            AND ( InvoiceDetail.CategoryID = 1 )
GO


