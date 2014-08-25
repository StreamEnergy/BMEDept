USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_ISTA_Aging_Payment_Rpt_Audit]    Script Date: 08/25/2014 12:20:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date				Author						Description
7/31/2013			Darren Williams				This SP is for the ISTA Aging Report. To run the queries that ISTA gave us.
12/13/2013			Darren Williams				Initial Release [sp_ISTA_Aging_Payment_Rpt_Audit] .
												Purpose of this SP is for the Daily Billing Report. To run the queries that ISTA gave us.
08/15/2014			Jide Akintoye				Format Stored Procedure




**********************************************************************************************/


CREATE PROCEDURE [dbo].[sp_ISTA_Aging_Payment_Rpt_Audit]
AS
    BEGIN

        DECLARE @StartDate AS DATETIME ,
            @EndDate AS DATETIME
		
        SET @StartDate = '1/1/2009'
        SET @EndDate = '12/31/2013'
	--SET @EndDate = (DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()),0)) )

        CREATE TABLE #temppayment
            ( CustID INT ,
              PaymentTotal DECIMAL(10 , 2) ,
              PostDate DATETIME ,
              PaymentID INT
            )

	--Get all Payments
        INSERT  INTO #temppayment
                SELECT 
		DISTINCT        pd.CustID ,
                        pd.Amount AS PaymentTotal ,
                        p.postdate ,
                        p.PaymentID
                FROM    Stream.dbo.Payment p
                INNER JOIN Stream.dbo.PaymentDetail pd ON pd.PaymentID = p.PaymentID
                INNER JOIN Stream.dbo.PaymentPending pp ON pp.PayDetId = pd.PayDetID
                INNER JOIN StreamMarket..tbl_820_Header h ON h.[820_Key] = pp.Header820_Key
                WHERE   ( h.TransactionDate > @StartDate
                          AND h.TransactionDate <= @EndDate
                        ) 
		
		
-- Get missing payments
        INSERT  INTO #temppayment
                SELECT 
	DISTINCT            pd.CustID ,
                        pd.Amount AS PaymentTotal ,
                        p.postdate ,
                        p.PaymentID
                FROM    Stream.dbo.Payment p
                LEFT JOIN Stream.dbo.PaymentDetail pd ON pd.PaymentID = p.PaymentID
                LEFT JOIN Stream.dbo.PaymentPending pp ON pp.PayDetId = pd.PayDetID
                LEFT JOIN StreamMarket..tbl_820_Header h ON h.[820_Key] = pp.Header820_Key
                WHERE   ( p.PaidDate > @StartDate
                          AND p.PaidDate <= @EndDate
                        )
                        AND pp.Header820_Key IS NULL
                        AND pp.PayDetId IS NULL
                ORDER BY p.PaymentID

        INSERT  INTO #temppayment
                SELECT 
		DISTINCT        pd.CustID ,
                        pd.Amount AS PaymentTotal ,
                        p.postdate ,
                        p.PaymentID
                FROM    Stream.dbo.Payment p
                INNER JOIN Stream.dbo.PaymentDetail pd ON pd.PaymentID = p.PaymentID
                INNER JOIN Stream.dbo.PaymentPending pp ON pp.PayDetId = pd.PayDetID
                INNER JOIN StreamMarket..tbl_820_Header h ON h.[820_Key] = pp.Header820_Key
                WHERE   h.TDSPDuns = 'BGEGAS001'
                        AND ( pp.PaymentDate > @StartDate
                              AND pp.PaymentDate <= @EndDate
                            ) 


	--Sum payments	
        SELECT  c.CustNo ,
                p.PremNo ,
                p.LDCID ,
                ldc.LDCShortName ,
                SUM(tp.PaymentTotal) AS 'Total Payments'
        INTO    #temppaymenttotal
        FROM    #temppayment tp
        INNER JOIN Stream.dbo.Customer c ON c.CustID = tp.CustId
        INNER JOIN Stream.dbo.Premise p ON p.CustID = tp.CustId
                                           AND p.PremID = ( SELECT
                                                              MAX(PremID)
                                                            FROM
                                                              Stream.dbo.Premise
                                                            WHERE
                                                              tp.CustId = CustId
                                                          )
        INNER JOIN Stream.dbo.LDCLookup ldc ON p.LDCID = ldc.LDCID
        GROUP BY c.CustNo ,
                p.PremNo ,
                p.LDCID ,
                ldc.LDCShortName

	--Get latest payment
        SELECT  MAX(PaymentId) AS PaymentId ,
                CustId
        INTO    #templatestpayment
        FROM    #temppayment
        GROUP BY CustId
	 
	--GET latest payment amount and date
        SELECT  c.CustNo ,
                pd.Amount ,
                CASE WHEN p.LDCID = 50 THEN pp.PaymentDate
                     ELSE h.TransactionDate
                END AS TransactionDate
        INTO    #templatestpaymentamt
        FROM    #templatestpayment t --Changed from INNER to LEFT 12/16/2013
        LEFT JOIN Stream.dbo.PaymentDetail pd ON pd.PaymentId = t.PaymentId
        LEFT JOIN Stream.dbo.PaymentPending pp ON pd.PayDetId = pp.PayDetId
        LEFT JOIN StreamMarket..tbl_820_Header h ON h.[820_Key] = pp.Header820_Key
        INNER JOIN Stream.dbo.Customer c ON c.CustId = t.CustId
        INNER JOIN Stream.dbo.Premise p ON p.CustID = c.CustID 


	--Get final results
        SELECT 
		DISTINCT
                ( t.CustNo ) ,
                c.CustStatus ,
                t.PremNo ,
                t.LDCID ,
                t.LDCShortName ,
                t.[Total Payments] ,
                lpa.Amount ,
                lpa.TransactionDate
        FROM    #temppaymenttotal t --Changed from INNER to LEFT 12/16/2013
        INNER JOIN #templatestpaymentamt lpa ON lpa.CustNo = t.CustNo
        INNER JOIN Stream.dbo.Customer c ON c.CustNo = t.CustNo
        ORDER BY t.CustNo


        DROP TABLE #temppaymenttotal
        DROP TABLE #temppayment
        DROP TABLE #templatestpayment
        DROP TABLE #templatestpaymentamt


-- ***** Old ISTA query without the BGE payments.
	--DECLARE 
	--	@StartDate AS DATETIME
	--	, @EndDate AS DATETIME
		
	--SET @StartDate = '1/1/2009'
	--SET @EndDate = (DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()),0)) )

	----Get all Payments
	--SELECT 
	--	DISTINCT pd.CustID  
	--	 , pd.Amount AS PaymentTotal  
	--	 , p.postdate 
	--	 , p.PaymentID
	--INTO #temppayment
	--FROM Stream.dbo.Payment p  
	--	INNER JOIN Stream.dbo.PaymentDetail pd ON pd.PaymentID = p.PaymentID
	--	INNER JOIN Stream.dbo.PaymentPending pp ON pp.PayDetId = pd.PayDetID
	--	INNER JOIN StreamMarket..tbl_820_Header h ON h.[820_Key] = pp.Header820_Key
	--WHERE h.TransactionDate > @StartDate
	--	AND h.TransactionDate <= @EndDate
		
	----Sum payments	
	--SELECT 
	--	c.CustNo
	--	, p.PremNo
	--	, p.LDCID
	--	, ldc.LDCShortName
	--	, SUM(tp.PaymentTotal) as 'Total Payments'
	--INTO #temppaymenttotal
	--FROM #temppayment tp 
	--	INNER JOIN Stream.dbo.Customer c ON c.CustID = tp.CustId
	--	INNER JOIN Stream.dbo.Premise p ON p.CustID = tp.CustId 
	--		AND p.PremID = (SELECT MAX(PremID) FROM Stream.dbo.Premise WHERE tp.CustId = CustId)
	--	Inner JOIN Stream.dbo.LDCLookup ldc ON p.LDCID = ldc.LDCID
	--GROUP BY c.CustNo, p.PremNo, p.LDCID, ldc.LDCShortName

	----Get latest payment
	--SELECT 
	--	MAX(PaymentId) AS PaymentId
	--	, CustId
	--INTO #templatestpayment
	--FROM #temppayment 
	--GROUP BY CustId

	----GET latest payment amount and date
	--SELECT 
	--	c.CustNo
	--	, pd.Amount
	--	, h.TransactionDate
	--INTO #templatestpaymentamt
	--FROM #templatestpayment t
	--INNER JOIN Stream.dbo.PaymentDetail pd ON pd.PaymentId = t.PaymentId
	--INNER JOIN Stream.dbo.PaymentPending pp ON pd.PayDetId = pp.PayDetId
	--INNER JOIN StreamMarket..tbl_820_Header h ON h.[820_Key] = pp.Header820_Key
	--INNER JOIN Stream.dbo.Customer c ON c.CustId = t.CustId


	----Get final results
	--SELECT 
	--	DISTINCT(t.CustNo)
	--	, c.CustStatus
	--	, t.PremNo
	--	, t.LDCID
	--	, t.LDCShortName
	--	, t.[Total Payments]
	--	, lpa.Amount
	--	, lpa.TransactionDate
	--FROM #temppaymenttotal t
	--INNER JOIN #templatestpaymentamt lpa on lpa.CustNo = t.CustNo
	--INNER JOIN Stream.dbo.Customer c on c.CustNo = t.CustNo


	--DROP TABLE #temppaymenttotal
	--DROP TABLE #temppayment
	--DROP TABLE #templatestpayment
	--DROP TABLE #templatestpaymentamt

    END












GO


