USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_ISTA_Daily_Billing_Rpt]    Script Date: 08/25/2014 12:20:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date				Author						Description
7/31/2013			Darren Williams				This SP is for the Daily Billing Report. To run the queries that ISTA gave us.
7/22/2013			Darren Williams				Initial Release [sp_ISTA_Daily_Billing_Rpt] .
												Purpose of this SP is for the Daily Billing Report. To run the queries that ISTA gave us.
08/15/2014			Jide Akintoye				Format Stored Procedure




**********************************************************************************************/



CREATE PROCEDURE [dbo].[sp_ISTA_Daily_Billing_Rpt]
AS
    BEGIN

        DECLARE @DivisionCode VARCHAR(10) = NULL ,
            @BeginDate DATETIME = '1/1/2009' ,
            @EndDate DATETIME = GETDATE() --'3/3/13' 
            ,
            @CSPDUNSID INT = NULL 
	 
        SET @EndDate = DATEADD(ms , -1 , DATEADD(d , 1 , @EndDate)) 
	 
        SET NOCOUNT ON 
	 
        CREATE TABLE #TmpInvoices
            ( InvoiceID INT NOT NULL ,
              PremID INT NOT NULL 
	-- , Released char(1) not null 
              ,
              SpecialCharges CHAR(1) NOT NULL
            ) 
	 
	 
        INSERT  INTO #TmpInvoices
                SELECT  i.InvoiceID ,
                        MAX(p.PremID) AS PremID 
	--, case when min(isnull(bd.InvoiceID,0)) = 0 then 'N' else 'Y' end 
                        ,
                        CASE WHEN MIN(ISNULL(sc.InvoiceID , 0)) = 0 THEN 'N'
                             ELSE 'Y'
                        END
                FROM    Stream.dbo.Invoice i
                JOIN    Stream.dbo.CustomerAdditionalInfo ca ON ca.CustID = i.CustID
                JOIN    Stream.dbo.Premise p ON ca.CustID = p.CustID 
	--left outer join InvoicePrintBatchDetail bd on i.InvoiceID = bd.InvoiceID 
                LEFT OUTER JOIN Stream.dbo.InvoiceSpecialCharges sc ON i.InvoiceId = sc.invoiceId
                WHERE   i.PostDate BETWEEN @BeginDate AND @EndDate
                        AND ca.CSPDUNSID = ISNULL(@CSPDUNSID , ca.CSPDUNSID)
                GROUP BY i.InvoiceID 
	 
        CREATE TABLE #BillingStatsTmp
            ( CustNo VARCHAR(100) NOT NULL ,
              CustName VARCHAR(100) NOT NULL ,
              CustType VARCHAR(2) NOT NULL ,
              CustID INT NOT NULL ,
              BillGroup INT NOT NULL ,
              DivisionCode VARCHAR(10) NULL ,
              BillingTypeID INT NOT NULL ,
              PrevBal DECIMAL(19 , 2) --not null 
              ,
              InvoiceID INT NOT NULL ,
              PostDate DATETIME NOT NULL ,
              InvDate DATETIME NOT NULL ,
              ServiceFrom DATETIME NULL ,
              ServiceTo DATETIME NULL ,
              InvAmt DECIMAL(19 , 2) NULL ,
              InvoiceType VARCHAR(8) NULL ,
              PremID INT NOT NULL 
	-- , Released char(1) null 
              ,
              SpecialCharges CHAR(1) NULL ,
              DetPremID INT NULL ,
              ConsQty DECIMAL(30 , 2) NULL ,
              Energy DECIMAL(30 , 2) NULL ,
              TDSP DECIMAL(30 , 2) NULL ,
              Meter DECIMAL(30 , 2) NULL ,
              Misc DECIMAL(30 , 2) NULL ,
              SalesTax DECIMAL(30 , 2) NULL ,
              Market VARCHAR(50) NOT NULL
            ) 
	 
        CREATE INDEX IX_#BillingStatsTmp_Cover ON #BillingStatsTmp ( 
        CustNo 
        , CustName 
        , CustType 
        , CustID 
        , BillGroup 
        , DivisionCode 
        , BillingTypeID 
        , PrevBal 
        , InvoiceID 
        , PostDate 
        , InvDate 
        , ServiceFrom 
        , ServiceTo 
        , InvAmt 
        , InvoiceType 
        , PremID 
        ) 
	 
        INSERT  INTO #BillingStatsTmp
                SELECT  c.CustNo ,
                        c.CustName ,
                        c.CustType ,
                        c.CustID ,
                        c.BillCycle AS BillGroup ,
                        cai.DivisionCode ,
                        i.BillingTypeID ,
                        arh.PrevBal ,
                        i.InvoiceID ,
                        i.PostDate ,
                        i.InvDate ,
                        i.ServiceFrom ,
                        i.ServiceTo ,
                        i.InvAmt ,
                        ( CASE WHEN i.Type IS NULL THEN 'Standard'
                               WHEN i.Type = 'Late' THEN 'Late Fee'
                               WHEN i.InvAmt >= 0 THEN 'Debit'
                               WHEN i.InvAmt < 0 THEN 'Credit'
                          END ) AS InvoiceType ,
                        ti.PremID 
	 --, ti.Released 
                        ,
                        ti.SpecialCharges ,
                        id.PremID AS DetPremID ,
                        CASE WHEN id.CategoryID = 1
                                  AND id.InvDetDesc = 'Base Cost'
                                  AND id.RateDescId NOT IN ( 5000 )
                             THEN InvDetQty
                             ELSE 0
                        END AS ConsQty ,
                        CASE WHEN id.CategoryID IN ( 1 , 7 , 8 )
                             THEN InvDetAmt
                             ELSE 0
                        END AS Energy ,
                        CASE WHEN id.CategoryID = 2 THEN InvDetAmt
                             ELSE 0
                        END AS TDSP ,
                        CASE WHEN id.CategoryID = 3 THEN InvDetAmt
                             ELSE 0
                        END AS Meter ,
                        CASE WHEN id.CategoryID = 5 THEN InvDetAmt
                             ELSE 0
                        END AS Misc ,
                        CASE WHEN id.CategoryID = 6 THEN InvDetAmt
                             ELSE 0
                        END AS SalesTax ,
                        CASE WHEN cspDunsID IN ( 1 , 3 , 8 , 12 ) THEN 'PA'
                             WHEN cspDunsID IN ( 2 , 11 , 13 ) THEN 'MD'
                             WHEN cspDunsID IN ( 4 , 5 , 6 ) THEN 'NJ'
                             WHEN cspDunsID IN ( 7 , 9 , 10 ) THEN 'NY'
                             ELSE 'n/a'
                        END AS MarketCode
                FROM    #TmpInvoices ti
                JOIN    Stream.dbo.Invoice i ON ti.InvoiceID = i.InvoiceID
                JOIN    Stream.dbo.InvoiceDetail id ON i.InvoiceID = id.InvoiceID
                JOIN    Stream.dbo.Customer c ON c.CustId = i.CustID
                JOIN    Stream.dbo.CustomerAdditionalInfo cai ON c.CustId = cai.CustId
                LEFT JOIN Stream.dbo.AccountsReceivableHistory arh ON i.AcctsRecHistID = arh.AcctsRecHistID 
        DROP TABLE #TmpInvoices 

        SELECT  CustNo ,
                CustName ,
                CustType ,
                CustID ,
                BillGroup ,
                DivisionCode ,
                BillingTypeID ,
                PrevBal ,
                InvoiceID ,
                PostDate ,
                InvDate ,
                ServiceFrom ,
                ServiceTo ,
                InvAmt ,
                InvoiceType ,
                PremID 
	 --, Released 
                ,
                SpecialCharges ,
                MAX(DetPremID) AS DetPremID ,
                SUM(ConsQty) AS ConsQty ,
                SUM(Energy) AS Energy ,
                SUM(TDSP) AS TDSP ,
                SUM(Meter) AS Meter ,
                SUM(Misc) AS Misc ,
                SUM(SalesTax) AS SalesTax ,
                Market AS Market
        INTO    #BillingStats
        FROM    #BillingStatsTmp
        GROUP BY CustNo ,
                CustName ,
                CustType ,
                CustID ,
                BillGroup ,
                DivisionCode ,
                BillingTypeID ,
                PrevBal ,
                InvoiceID ,
                PostDate ,
                InvDate ,
                ServiceFrom ,
                ServiceTo ,
                InvAmt ,
                InvoiceType ,
                PremID 
	 --, Released 
                ,
                SpecialCharges ,
                Market 
        DROP TABLE #BillingStatsTmp 
	 
        SET NOCOUNT OFF 
	 
        SELECT  bs.InvoiceID AS 'Invoice No' ,
                bs.InvoiceType AS 'Inv Type' ,
                CONVERT(CHAR(8) , bs.PostDate , 1) AS 'Post Date' ,
                CONVERT(CHAR(8) , bs.InvDate , 1) AS 'Inv Date' ,
                CONVERT(CHAR(8) , bs.ServiceFrom , 1) AS 'Service From' ,
                CONVERT(CHAR(8) , bs.ServiceTo , 1) AS 'Service To' ,
                p.PremType AS Commodity ,
                bs.CustNo AS 'Account No' ,
                p.PremNo AS 'LDC Account No' ,
                bs.CustName AS 'Cust Name' ,
                bs.CustType AS 'Cust Type' ,
                bs.BillGroup AS 'Bill Group' ,
                CASE WHEN bs.BillingTypeID = '1' THEN 'Supplier Consolidated'
                     WHEN bs.BillingTypeID = '2' THEN 'Bill Ready'
                     WHEN bs.BillingTypeID = '3' THEN 'Rate Ready'
                     WHEN bs.BillingTypeID = '4' THEN 'Dual'
                     ELSE 'n/a'
                END AS 'Billing Type' 
	 --, bs.Released 
                ,
                bs.SpecialCharges AS 'Special Charges' ,
                bs.PrevBal AS 'Prev Bal' ,
                bs.DivisionCode AS Division ,
                bs.ConsQty AS 'Energy Qty' ,
                bs.Energy ,
                bs.TDSP ,
                bs.Meter ,
                bs.[Misc] ,
                bs.SalesTax AS 'Sales Tax' ,
                bs.InvAmt AS 'Inv Amount' ,
                p.TaxAssessment AS 'Tax Assessment' ,
                a.GeoCode ,
                a.City ,
                a.County ,
                a.Zip ,
                pr.ProductCode AS 'Product Code' ,
                CASE WHEN c.TDSPTemplateID = 1 THEN 'Rate Ready'
                     WHEN c.TDSPTemplateID = 2 THEN 'Resi Unbundled'
                     WHEN c.TDSPTemplateID = 3 THEN 'Not Applicable'
                     ELSE 'Not Identified'
                END AS 'Tdsp Template' ,
                CASE WHEN p.LDCID IN ( 1 , 2 , 3 , 4 , 5 , 6 ) THEN 'Texas'
                     WHEN p.LDCID IN ( 30 , 54 ) THEN 'Connecticut'
                     WHEN p.LDCID IN ( 58 , 66 , 61 ) THEN 'Pennsylvania'
                     ELSE 'N/A'
                END AS Market ,
                l.LDCShortName AS Utility
        FROM    #BillingStats bs
        JOIN    Stream.dbo.BillingType bt ON bs.BillingTypeID = bt.BillingTypeID
        JOIN    Stream.dbo.Customer c ON bs.CustID = c.CustID
        LEFT OUTER JOIN Stream.dbo.Premise p ON p.PremID = ISNULL(bs.DetPremID ,
                                                              bs.PremID)
        LEFT OUTER JOIN Stream.dbo.LDCLookup l ON l.LDCID = p.LDCID
        LEFT OUTER JOIN Stream.dbo.Address a ON a.AddrID = p.AddrID
        LEFT OUTER JOIN Stream.dbo.RateTransition rt ON bs.CustID = rt.CustID
                                                        AND bs.ServiceTo BETWEEN rt.SwitchDate
                                                              AND
                                                              ISNULL(rt.EndDate ,
                                                              GETDATE())
        LEFT OUTER JOIN Stream.dbo.Product pr ON rt.RateID = pr.RateID
        ORDER BY bs.PostDate 
	
	--Return 
	
        DROP TABLE #BillingStats 

    END



GO


