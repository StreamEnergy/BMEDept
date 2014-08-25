USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_ISTA_Aging_Invoices_Rpt_Audit]    Script Date: 08/25/2014 12:20:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date				Author						Description
8/7/2013			Darren Williams				This SP is for the ISTA Aging Report. To run the queries that ISTA gave us.
8/7/2013			Darren Williams				Initial Release [sp_ISTA_Aging_Invoices_Rpt_Audit] .
												Purpose of this SP is for the Daily Billing Report. To run the queries that ISTA gave us.
08/15/2014			Jide Akintoye				Format Stored Procedure




**********************************************************************************************/




CREATE PROCEDURE [dbo].[sp_ISTA_Aging_Invoices_Rpt_Audit]
AS
    BEGIN

        DECLARE @StartDate AS DATETIME ,
            @EndDate AS DATETIME
		
        SET @StartDate = '1/1/2009'
        SET @EndDate = '12/31/2013'
	--SET @EndDate = (DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()),0)) )

	--Get all Invoices
        SELECT 
		DISTINCT
                i.CustID ,
                i.InvAmt ,
                i.InvDate ,
                i.DueDate ,
                i.InvoiceID
        INTO    #tempinv
        FROM    Stream.dbo.Invoice i
        WHERE   i.InvDate > @StartDate
                AND i.InvDate <= @EndDate
		
	--Sum invoices
        SELECT  c.CustNo ,
                p.LDCID ,
                p.PremNo ,
                p.PremType ,
                p.StatusID ,
                ldc.LDCShortName ,
                ldc.MarketID ,
                SUM(ti.InvAmt) AS 'Total Invoices'
        INTO    #tempinvtotal
        FROM    #tempinv ti
        INNER JOIN Stream.dbo.Customer c ON c.CustID = ti.CustId
        INNER JOIN Stream.dbo.Premise p ON p.CustID = ti.CustId
                                           AND p.PremID = ( SELECT
                                                              MAX(PremID)
                                                            FROM
                                                              Stream.dbo.Premise
                                                            WHERE
                                                              ti.CustId = CustId
                                                          )
        INNER JOIN Stream.dbo.LDCLookup ldc ON p.LDCID = ldc.LDCID
        GROUP BY c.CustNo ,
                p.LDCID ,
                ldc.LDCShortName ,
                p.PremNo ,
                p.PremType ,
                p.StatusID ,
                ldc.MarketID

	--Get latest invoiceID
        SELECT  MAX(InvoiceID) AS InvoiceId ,
                CustId
        INTO    #templatestinvoice
        FROM    #tempinv
        GROUP BY CustId

	--Get latest invoice amount and date
        SELECT  c.CustNo ,
                InvDate ,
                DueDate ,
                InvAmt
        INTO    #templatestinvoiceamt
        FROM    #templatestinvoice t
        INNER JOIN Stream.dbo.Invoice i ON i.InvoiceID = t.InvoiceId
        INNER JOIN Stream.dbo.Customer c ON c.CustId = t.CustId


	--Get final results
        SELECT  it.CustNo ,
                it.LDCID ,
                it.LDCShortName ,
                ca.ClientAccountNo ,
                it.PremNo ,
                it.PremType ,
                it.StatusID ,
                c.CustStatus ,
                c.CustType ,
                it.[Total Invoices] ,
                t.InvAmt AS 'Last Invoice Amount' ,
                t.InvDate AS 'Last Invoice Date' ,
                t.DueDate ,
                CAST(GETDATE() - ( t.InvDate ) AS INT) AS days_aged ,
                CASE WHEN it.LDCShortName = 'PEPCODC' THEN 'DC'
                     ELSE m.StateAbbr
                END AS 'State' ,
                a.Zip
        FROM    #tempinvtotal it
        INNER JOIN #templatestinvoiceamt t ON t.CustNo = it.CustNo
        INNER JOIN Stream.dbo.Customer c ON c.CustNo = t.CustNo
        INNER JOIN Stream.dbo.CustomerAdditionalInfo ca ON ca.CustID = c.CustID
        INNER JOIN StreamInternal.dbo.Market m ON m.MarketId = it.MarketID
        LEFT JOIN Stream.dbo.Address a ON a.AddrID = c.MailAddrId

        DROP TABLE #tempinvtotal
        DROP TABLE #tempinv
        DROP TABLE #templatestinvoice
        DROP TABLE #templatestinvoiceamt

    END







GO


