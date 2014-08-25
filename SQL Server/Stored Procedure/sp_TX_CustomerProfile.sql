USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_TX_CustomerProfile]    Script Date: 08/25/2014 12:24:14 ******/
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

CREATE PROCEDURE [dbo].[sp_TX_CustomerProfile]
    ( @StartDate DATETIME
    , @EndDate DATETIME
--, @State NVARCHAR (MAX) 
--, @Status NVARCHAR (MAX) 

    )
AS
    BEGIN


----Begin Test Section
--        DECLARE @StartDate DATETIME = '01/01/2005'
--        DECLARE @EndDate DATETIME = '12/31/2006'
----End Test Section

        IF OBJECT_ID(N'tempdb..#CustProfile' , N'U') IS NOT NULL
            DROP TABLE #CustProfile;
        CREATE TABLE #CustProfile
            ( MonthID NVARCHAR(10)
            , ServiceMonth NVARCHAR(50)
            , Dimension NVARCHAR(10)
            , RecordCount INT
            ); 
        INSERT  INTO #CustProfile
/**************************************************
/*Begin Premise Count*/
***************************************************/
                SELECT DISTINCT
                        'MonthID' = CONVERT(VARCHAR(7) , CP.CalendarDate , 120)
                      , 'ServiceMonth' = SUBSTRING(DATENAME(MONTH ,
                                                            CP.CalendarDate) ,
                                                   1 , 3) + ' '
                        + DATENAME(YEAR , CP.CalendarDate)
                      , 'Dimension' = CP.DayofMonth
                      , 'RecordCount' = COUNT(DISTINCT CP.LDCNo)
                FROM    ( SELECT 	DISTINCT
                                    C.LDCNo
                                  , C.BeginServiceDate
                                  , C.EndServiceDate
                                  , CD.CalendarDate
                                  , CD.DayofMonth
                          FROM      StreamInternal.dbo.CustomerProfile C
                          LEFT JOIN ( SELECT    c.CalendarDate
                                              , CASE WHEN c.CalendarDate = DATEADD(s ,
                                                              +0 ,
                                                              DATEADD(mm ,
                                                              DATEDIFF(m , 0 ,
                                                              c.CalendarDate)
                                                              + 0 , 0))
                                                     THEN 'Begin'
                                                END AS 'DayofMonth'
                                      FROM      StreamInternal.dbo.Calendar c
                                      WHERE     CalendarDate >= @StartDate
                                                AND CalendarDate <= @EndDate
                                    ) CD ON CD.CalendarDate BETWEEN C.BeginServiceDate
                                                            AND
                                                              ISNULL(C.EndServiceDate ,
                                                              '12/31/2999')
                                            AND C.[State] = 'TX'
                                            AND C.BeginServiceDate <> ISNULL(C.EndServiceDate ,
                                                              '12/31/2999')
                          WHERE     CD.DayofMonth IN ( 'End' , 'Begin' )
                                    AND CD.CalendarDate <= GETDATE()
                        ) CP
                GROUP BY CP.CalendarDate
                      , CP.DayofMonth
--ORDER BY MonthID	
                UNION ALL
/**************************************************
Count ALL New Customer Additions*
***************************************************/
                SELECT DISTINCT --TOP 1000
                        'MonthID' = CONVERT(VARCHAR(7) , [BeginServiceDate] , 120)
                      , 'ServiceMonth' = SUBSTRING(DATENAME(MONTH ,
                                                            [BeginServiceDate]) ,
                                                   1 , 3) + ' '
                        + DATENAME(YEAR , [BeginServiceDate])
                      , 'Dimension' = 'Additions'
                      , 'RecordCount' = COUNT(DISTINCT enroll_orig_transaction_id)
                FROM    StreamInternal.dbo.TX_Enroll_Net
                WHERE   BeginServiceDate >= @StartDate
                        AND BeginServiceDate <= @EndDate
                GROUP BY SUBSTRING(DATENAME(MONTH , [BeginServiceDate]) , 1 ,
                                   3) + ' ' + DATENAME(YEAR ,
                                                       [BeginServiceDate])
                      , DATEPART(MONTH , BeginServiceDate)
                      , CONVERT(VARCHAR(7) , [BeginServiceDate] , 120)
--ORDER BY CONVERT(VARCHAR(7) , [BeginServiceDate] , 120)
                UNION ALL
/**************************************************
--Count ALL Customer Dropped*
***************************************************/
                SELECT DISTINCT --TOP 1000
                        'MonthID' = CONVERT(VARCHAR(7) , EndServiceDate , 120)
                      , 'ServiceMonth' = SUBSTRING(DATENAME(MONTH ,
                                                            EndServiceDate) ,
                                                   1 , 3) + ' '
                        + DATENAME(YEAR , EndServiceDate)
                      , 'Dimension' = 'Attritions'
                      , 'RecordCount' = COUNT(DISTINCT drop_sender_transaction_id)
                FROM    StreamInternal.dbo.TX_Drop_Net
                WHERE   EndServiceDate >= @StartDate
                        AND EndServiceDate <= @EndDate
                GROUP BY SUBSTRING(DATENAME(MONTH , EndServiceDate) , 1 , 3)
                        + ' ' + DATENAME(YEAR , EndServiceDate)
                      , DATEPART(MONTH , EndServiceDate)
                      , CONVERT(VARCHAR(7) , EndServiceDate , 120)
--ORDER BY MonthID
                UNION ALL    
/**************************************************
/*End Premise Count*/
                ***************************************************/

SELECT DISTINCT
        'MonthID' = CONVERT(VARCHAR(7) , CP.CalendarDate , 120)
      , 'ServiceMonth' = SUBSTRING(DATENAME(MONTH , CP.CalendarDate) , 1 , 3)
        + ' ' + DATENAME(YEAR , CP.CalendarDate)
      , 'Dimension' = CP.DayofMonth
      , 'RecordCount' = COUNT(DISTINCT CP.LDCNo)
FROM    ( SELECT 	DISTINCT
                    C.LDCNo
                  , C.BeginServiceDate
                  , C.EndServiceDate
                  , CD.CalendarDate
                  , CD.DayofMonth
          FROM      StreamInternal.dbo.CustomerProfile C
          LEFT JOIN ( SELECT    c.CalendarDate
                              , CASE WHEN CONVERT(VARCHAR(8) , c.CalendarDate , 112) = CONVERT(VARCHAR(8) , DATEADD(s ,
                                                              -1 ,
                                                              DATEADD(mm ,
                                                              DATEDIFF(m , 0 ,
                                                              c.CalendarDate)
                                                              + 1 , 0)) , 112)
                                     THEN 'End'
                                END AS 'DayofMonth'
                      FROM      StreamInternal.dbo.Calendar c
                      WHERE     CalendarDate >= @StartDate
                                AND CalendarDate <= @EndDate
                    ) CD ON CD.CalendarDate BETWEEN C.BeginServiceDate
                                            AND     ISNULL(C.EndServiceDate ,
                                                           '12/31/2999')
                            AND C.[State] = 'TX'
                            AND C.BeginServiceDate <> ISNULL(C.EndServiceDate ,
                                                             '12/31/2999')
          WHERE     CD.DayofMonth IN ( 'End' , 'Begin' )
                    AND CD.CalendarDate <= GETDATE()
        ) CP
GROUP BY CP.CalendarDate
      , CP.DayofMonth
ORDER BY MonthID	
   
/**************************************************
/*Final Select*/
***************************************************/  
 
        SELECT  MonthID
              , ServiceMonth
              , Dimension
              , RecordCount
        FROM    #CustProfile
        ORDER BY MonthID
    END


GO


