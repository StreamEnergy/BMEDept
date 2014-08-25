USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_TX_ERCOTCount]    Script Date: 08/25/2014 12:24:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







/*
============================================================================
************************** Notes/Change Log *******************************
==========================================================================
Date				Author						Description
08/06/2014 			Jide Akintoye				Count # of TX Net Additions, and Attritions,
												and Total count of LDC @ the Begin and 
												End of the month



==========================================================================						   
*/

CREATE PROCEDURE [dbo].[sp_TX_ERCOTCount]
    ( @StartDate DATETIME
    , @EndDate DATETIME
--, @State NVARCHAR (MAX) 
--, @Status NVARCHAR (MAX) 

    )
AS
    BEGIN


----Begin Test Section
--    DECLARE @StartDate DATETIME = '01/01/2013'
--    DECLARE @EndDate DATETIME = '12/31/2014'
----End Test Section

        IF OBJECT_ID(N'tempdb..#ERCOTCount' , N'U') IS NOT NULL
            DROP TABLE #ERCOTCount;
        CREATE TABLE #ERCOTCount
            ( MonthID NVARCHAR(10)
            , ServiceMonth NVARCHAR(50)
            , Dimension NVARCHAR(20)
            , RecordCount INT
            ); 
        INSERT  INTO #ERCOTCount
/**************************************************
/*Begin Premise Count*/
***************************************************/
                SELECT --DISTINCT
                        'MonthID' = CONVERT(VARCHAR(7) , ErcotDate + 1 , 120)--ErcotDate + 1--
                      , 'ServiceMonth' = SUBSTRING(DATENAME(MONTH ,
                                                            ErcotDate + 1) , 1 ,
                                                   3) + ' ' + DATENAME(YEAR ,
                                                              ErcotDate + 1)
                      , 'Dimension' = 'Begin||ERCOT'--CountType
                      , RecordCount
                FROM    StreamInternal.[dbo].[ERCOT_Numbers]
                WHERE   CountType = 'End'
                        AND ErcotDate + 1 >= @StartDate
                        AND ErcotDate + 1 <= @EndDate
                UNION ALL
/**************************************************
Count ALL New Customer Additions*
***************************************************/
                SELECT DISTINCT TOP 1000
                        'MonthID' = CONVERT(VARCHAR(7) , [BeginServiceDate] , 120)--[BeginServiceDate]--
                      , 'ServiceMonth' = SUBSTRING(DATENAME(MONTH ,
                                                            [BeginServiceDate]) ,
                                                   1 , 3) + ' '
                        + DATENAME(YEAR , [BeginServiceDate])
                      , 'Dimension' = 'CustAddition'
                      , 'RecordCount' = COUNT(DISTINCT enroll_orig_transaction_id)
                FROM    StreamInternal.dbo.TX_Enroll_Net
                WHERE   BeginServiceDate >= @StartDate
                        AND BeginServiceDate <= @EndDate
                GROUP BY SUBSTRING(DATENAME(MONTH , [BeginServiceDate]) , 1 ,
                                   3) + ' ' + DATENAME(YEAR ,
                                                       [BeginServiceDate])
                      , DATEPART(MONTH , BeginServiceDate)
                      , BeginServiceDate--CONVERT(VARCHAR(7) , [BeginServiceDate] , 120)
--ORDER BY CONVERT(VARCHAR(7) , [BeginServiceDate] , 120)
                UNION ALL
/**************************************************
--Count ALL Customer Dropped*
***************************************************/
                SELECT DISTINCT TOP 1000
                        'MonthID' = CONVERT(VARCHAR(7) , EndServiceDate , 120)--EndServiceDate--
                      , 'ServiceMonth' = SUBSTRING(DATENAME(MONTH ,
                                                            EndServiceDate) ,
                                                   1 , 3) + ' '
                        + DATENAME(YEAR , EndServiceDate)
                      , 'Dimension' = 'CustAttrition'
                      , 'RecordCount' = COUNT(DISTINCT drop_sender_transaction_id)
                FROM    StreamInternal.dbo.TX_Drop_Net
                WHERE   EndServiceDate >= @StartDate
                        AND EndServiceDate <= @EndDate
                GROUP BY SUBSTRING(DATENAME(MONTH , EndServiceDate) , 1 , 3)
                        + ' ' + DATENAME(YEAR , EndServiceDate)
                      , DATEPART(MONTH , EndServiceDate)
                      , EndServiceDate--CONVERT(VARCHAR(7) , EndServiceDate , 120)
--ORDER BY MonthID
                UNION ALL    
/**************************************************
/*End Premise Count*/
                ***************************************************/
            SELECT --DISTINCT
                    'MonthID' = CONVERT(VARCHAR(7) , ErcotDate , 120)--ErcotDate--
                  , 'ServiceMonth' = SUBSTRING(DATENAME(MONTH , ErcotDate) , 1 ,
                                               3) + ' ' + DATENAME(YEAR ,
                                                              ErcotDate)
                  , 'Dimension' = 'End||ERCOT'--CountType
                  , RecordCount
            FROM    StreamInternal.[dbo].[ERCOT_Numbers]
            WHERE   CountType = 'End'
                    AND ErcotDate >= @StartDate
                    AND ErcotDate <= @EndDate
           
   
/**************************************************
/*Final Select*/
***************************************************/  
 
        SELECT  MonthID
              , ServiceMonth
              , Dimension
              , RecordCount
        FROM    #ERCOTCount
        ORDER BY MonthID
    END




GO


