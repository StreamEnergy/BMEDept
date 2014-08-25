USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_ISTA_Aging_Adjustment_Rpt]    Script Date: 08/25/2014 12:20:22 ******/
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
8/7/2013			Darren Williams				Initial Release [sp_ISTA_Aging_Adjustment_Rpt] .
												Purpose of this SP is for the Daily Billing Report. To run the queries that ISTA gave us.
08/15/2014			Jide Akintoye				Format Stored Procedure



**********************************************************************************************/




CREATE PROCEDURE [dbo].[sp_ISTA_Aging_Adjustment_Rpt]
AS
    BEGIN

        DECLARE @StartDate AS DATETIME ,
            @EndDate AS DATETIME
		
        SET @StartDate = '1/1/2009'
        SET @EndDate = ( DATEADD(s , -1 ,
                                 DATEADD(mm , DATEDIFF(m , 0 , GETDATE()) , 0)) )

	--Get all Adjustments
        SELECT  a.CustID ,
                a.ARAdjAmt ,
                a.ARAdjDate
        INTO    #tempar
        FROM    Stream.dbo.ARAdjustment a
        WHERE   a.ARAdjDate > @StartDate
                AND a.ARAdjDate < @EndDate
		
		
	--Sum adjusments
        SELECT  c.CustNo ,
                p.PremNo ,
                p.LDCID ,
                ldc.LDCShortName ,
                SUM(ta.ArAdjAmt) AS 'Total Adjustments'
        INTO    #tempartotal
        FROM    #tempar ta
        INNER JOIN Stream.dbo.Customer c ON c.CustID = ta.CustId
        INNER JOIN Stream.dbo.Premise p ON p.CustID = ta.CustId
                                           AND p.PremID = ( SELECT
                                                              MAX(PremID)
                                                            FROM
                                                              Stream.dbo.Premise
                                                            WHERE
                                                              ta.CustId = CustId
                                                          )
        INNER JOIN Stream.dbo.LDCLookup ldc ON p.LDCID = ldc.LDCID
        GROUP BY c.CustNo ,
                p.PremNo ,
                p.LDCID ,
                ldc.LDCShortName

	--Get final results
        SELECT  *
        FROM    #tempartotal

        DROP TABLE #tempartotal
        DROP TABLE #tempar

    END




GO


