USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_NE_Billing_Transaction201402051023 Backup Matt Baker]    Script Date: 08/26/2014 15:11:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
7/19/2013				Steve Nelson						Initial Release [v_NE_Billing_Transaction] .
															Purpose of this view is to capture northest billing transactions.
						   
7/22/2013				Steve Nelson						Update: Add Status code field 
7/24/2013				Steve Nelson						Update: Add Inv Date (810_InvDate) field 						   
12/18/2013				Steve Nelson						Update: Add ServiceActionCode AS [867_ServiceActionCode] field 
2/4/2014				Steve Nelson						Update:  Add ServiceActionCode as [824_ActionCode] field
															Add StatusCode (824_Code) field
08/26/2014 				Jide Akintoye						Formatted VIEW



**********************************************************************************************/



CREATE VIEW [dbo].[v_NE_Billing_Transaction201402051023 Backup Matt Baker]
AS
    SELECT
  DISTINCT  CustomerTransactionRequest.CustID ,
            CustomerTransactionRequest.PremID ,
            CustomerTransactionRequest.ESIID AS [LDC Number] ,
            CustomerTransactionRequest.TransactionNumber AS TransNum ,
            CustomerTransactionRequest.TransactionDate AS TransDate ,
            CustomerTransactionRequest.TransactionType AS [867] ,
            CustomerTransactionRequest.TransactionDate AS [867_Date] ,
            CustomerTransactionRequest.ServiceActionCode AS [867_ServiceAction] ,
            Consumption.EndRead - Consumption.BegRead AS Usage ,
            CustomerTransactionRequest_1.TransactionType AS [810] ,
            CustomerTransactionRequest_1.TransactionDate AS [810_Date] ,
            CustomerTransactionRequest_1.StatusReason AS [810_Value] ,
            Invoice.InvDate AS [810_InvDate] ,
            Invoice.InvAmt AS [810_InvAmt] ,
            BillingType.[Description] AS BillingType ,
            CustomerTransactionRequest_2.TransactionType AS [824] ,
            CustomerTransactionRequest_2.TransactionDate AS [824_Date] ,
            CustomerTransactionRequest_2.ServiceActionCode AS [824_ActionCode] ,
            CustomerTransactionRequest_2.StatusCode AS [824_Code] ,
            CustomerTransactionRequest_2.StatusReason AS [824_Value] ,
            tbl_820_Detail.ProcessDate AS [820_Date] ,
            tbl_820_Detail.PaymentAmount AS [820_PayAmt] ,
            NULL AS [814] ,
            NULL AS [814_Date] ,
            NULL AS [814_ActionCode] ,
            NULL AS [814_Value]
    FROM    ( ( ( ( ( ( Stream.dbo.CustomerTransactionRequest CustomerTransactionRequest_1
                        LEFT OUTER JOIN Stream.dbo.CustomerTransactionRequest CustomerTransactionRequest_2 ON ( CustomerTransactionRequest_1.TransactionNumber = CustomerTransactionRequest_2.ReferenceNumber
                                                              AND CustomerTransactionRequest_2.TransactionType = 824
                                                              )
                      )
                      RIGHT OUTER JOIN StreamMarket.dbo.tbl_810_Header tbl_810_Header ON ( tbl_810_Header.[810_Key] = CustomerTransactionRequest_1.SourceID
                                                              AND CustomerTransactionRequest_1.TransactionType = '810'
                                                              )
                    )
                    RIGHT OUTER JOIN Stream.dbo.CustomerTransactionRequest CustomerTransactionRequest ON ( CustomerTransactionRequest.TransactionNumber = tbl_810_Header.ReleaseNbr )
                  )
                  LEFT OUTER JOIN Stream.dbo.Consumption Consumption ON ( CustomerTransactionRequest.RequestID = Consumption.RequestID )
                )
                LEFT OUTER JOIN Stream.dbo.Invoice Invoice ON ( Consumption.InvoiceID = Invoice.InvoiceID )
              )
              LEFT OUTER JOIN Stream.dbo.BillingType BillingType ON ( Invoice.BillingTypeID = BillingType.BillingTypeID )
            )
    LEFT OUTER JOIN StreamMarket.dbo.tbl_820_Detail tbl_820_Detail ON ( CustomerTransactionRequest.TransactionNumber = tbl_820_Detail.CrossReferenceNbr )
    WHERE   ( CustomerTransactionRequest.TransactionType = '867' )
            AND ( CustomerTransactionRequest.ActionCode = '03' )
    UNION ALL
    SELECT  CustomerTransactionRequest.CustID ,
            CustomerTransactionRequest.PremID ,
            CustomerTransactionRequest.ESIID AS [LDC Number] ,
            CustomerTransactionRequest.TransactionNumber AS TransNum ,
            CustomerTransactionRequest.TransactionDate AS TranDate ,
            NULL AS [867] ,
            NULL AS [867_Date] ,
            NULL AS [867_ServiceAction] ,
            NULL AS Usage ,
            NULL AS [810] ,
            NULL AS [810_Date] ,
            NULL AS [810_Value] ,
            NULL AS [810_InvDate] ,
            NULL AS [810_InvAmt] ,
            NULL AS BillingType ,
            NULL AS [824] ,
            NULL AS [824_Date] ,
            NULL AS [824_ActionCode] ,
            NULL AS [824_Code] ,
            NULL AS [824_Value] ,
            NULL AS [820_Date] ,
            NULL AS [820_PayAmt] ,
            CustomerTransactionRequest.TransactionType AS [814] ,
            CustomerTransactionRequest.TransactionDate AS [814_Date] ,
            CustomerTransactionRequest.ActionCode AS [814_ActionCode] ,
            CustomerTransactionRequest.StatusReason AS [814_Value]
    FROM    Stream.dbo.CustomerTransactionRequest CustomerTransactionRequest
    WHERE   ( CustomerTransactionRequest.TransactionType = '814' )



GO


