USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_MvInMvOt_Gains]    Script Date: 08/25/2014 12:21:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--USE [StreamInternal]
--GO

--/****** Object:  StoredProcedure [dbo].[sp_MvInMvOt_Gains]    Script Date: 08/05/2014 10:04:24 ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

--/*
--============================================================================
--************************** Notes/Change Log *******************************
--==========================================================================
--Date				Author						Description
--08/05/2014 			Jide Akintoye				Count # of Move in Move out Gains by combining
--												the Net Additions, the total Transfer of Service (TOS)(same customer, diff esiid, within 30 days)
--												,count of the R1 (Diff Customer, Same ESIID) and 
--												the count of the R2 (same esiid, enroll within 90days after drop)
														   



--==========================================================================						   
--*/

CREATE PROCEDURE [dbo].[sp_MvInMvOt_Gains]
(@StartDate DATETIME
,@EndDate DATETIME
--, @State NVARCHAR (MAX) 
--, @Status NVARCHAR (MAX) 

)
AS
BEGIN


---- --Begin Test Section
--    DECLARE @StartDate DATETIME = '10/31/2013'
--    DECLARE @EndDate DATETIME = '03/31/2014'
----DECLARE @SDate VARCHAR(7)
----DECLARE @EDate VARCHAR(7)
------End Test Section

----SELECT  @SDate = CONVERT(VARCHAR(7) , @StartDate , 120) 
----SELECT  @EDate = CONVERT(VARCHAR(7) , @EndDate , 120) 
-------------------------------
-- Net Added Transaction
-------------------------------
    IF OBJECT_ID(N'tempdb..#NetEnroll' , N'U') IS NOT NULL
        DROP TABLE #NetEnroll;
    CREATE TABLE #NetEnroll
        ( BeginServiceDate DATETIME
        , MonthID NVARCHAR(10)
        , BeginServiceMonth NVARCHAR(50)
        , EnrollType NVARCHAR(10)
        , RecordCount INT
        );    
    WITH    NetEnroll
              AS ( SELECT  DISTINCT
                            BeginServiceDate
                          , 'BeginServiceMonth' = SUBSTRING(DATENAME(MONTH ,
                                                              [BeginServiceDate]) ,
                                                            1 , 3) + ' '
                            + DATENAME(YEAR , [BeginServiceDate])
                          , N.[YYYY-MM]
                          , EnrollType = 'NewEnroll'
                          , 'NetEnroll' = COUNT(DISTINCT N.enroll_orig_transaction_id)
                   FROM     StreamInternal.dbo.TX_Enroll_Net N
                   WHERE    [BeginServiceDate] >= @StartDate
                            AND [BeginServiceDate] <= @EndDate
                   GROUP BY DATENAME(MONTH , [BeginServiceDate]) + ' '
                            + DATENAME(YEAR , [BeginServiceDate])
                          , [BeginServiceDate]
                          , N.[YYYY-MM]
                 )
        INSERT  INTO #NetEnroll
                SELECT  BeginServiceDate
                      , 'MonthID' = [YYYY-MM]--DATEPART(MONTH , BeginServiceDate)
                      , BeginServiceMonth
                      , EnrollType
                      , 'NetEnroll' = SUM(NetEnroll)
                FROM    NetEnroll
                GROUP BY BeginServiceDate
                      , BeginServiceMonth
                      , EnrollType
                      , [YYYY-MM]
                ORDER BY [BeginServiceDate]
     --SELECT 'MonthID' = [YYYY-MM]
     --     , 'Month' = BeginServiceMonth
     --     , 'NetAddition' = SUM(NetAddition)
     --FROM   Net_TOS
     --GROUP BY BeginServiceMonth
     --     , [YYYY-MM]
     --ORDER BY [YYYY-MM];
 
    --SELECT  *
    --FROM    #NetEnroll
    
-------------------------------
-- Transfer of Service (TOS) (same customer, diff esiid, within 30 days)
-------------------------------
    IF OBJECT_ID(N'tempdb..#Net_TOS' , N'U') IS NOT NULL
        DROP TABLE #Net_TOS;
    CREATE TABLE #Net_TOS
        ( BeginServiceDate DATETIME
        , MonthID NVARCHAR(10)
        , BeginServiceMonth NVARCHAR(50)
        , EnrollType NVARCHAR(10)
        , RecordCount INT
        );    
    WITH    NetTOS
              AS ( SELECT  DISTINCT
                            BeginServiceDate
                          , 'BeginServiceMonth' = SUBSTRING(DATENAME(MONTH ,
                                                              [BeginServiceDate]) ,
                                                            1 , 3) + ' '
                            + DATENAME(YEAR , [BeginServiceDate])
                          , N.[YYYY-MM]
                          , EnrollType = 'TOS'
                          , 'Net_TOS' = COUNT(DISTINCT N.enroll_orig_transaction_id)
                   FROM     StreamInternal.dbo.[TX_Enroll_TOS] N
                   WHERE    [BeginServiceDate] >= @StartDate
                            AND [BeginServiceDate] <= @EndDate
                   GROUP BY DATENAME(MONTH , [BeginServiceDate]) + ' '
                            + DATENAME(YEAR , [BeginServiceDate])
                          , [BeginServiceDate]
                          , N.[YYYY-MM]
                 )
        INSERT  INTO #Net_TOS
                SELECT  BeginServiceDate
                      , 'MonthID' = [YYYY-MM]--DATEPART(MONTH , BeginServiceDate)
                      , BeginServiceMonth
                      , EnrollType
                      , 'Net_TOS' = SUM(Net_TOS)
                FROM    NetTOS
                GROUP BY BeginServiceDate
                      , BeginServiceMonth
                      , EnrollType
                      , [YYYY-MM]
                ORDER BY [BeginServiceDate]
     --SELECT 'MonthID' = [YYYY-MM]
     --     , 'Month' = BeginServiceMonth
     --     , 'NetAddition' = SUM(NetAddition)
     --FROM   Net_TOS
     --GROUP BY BeginServiceMonth
     --     , [YYYY-MM]
     --ORDER BY [YYYY-MM];
 
    --SELECT  *
    --FROM    #Net_TOS
    
 ------------------------------
--R1 (Diff Customer, Same ESIID)
-------------------------------
    IF OBJECT_ID(N'tempdb..#Net_Recycle1' , N'U') IS NOT NULL
        DROP TABLE #Net_Recycle1;
    CREATE TABLE #Net_Recycle1
        ( BeginServiceDate DATETIME
        , MonthID NVARCHAR(10)
        , BeginServiceMonth NVARCHAR(50)
        , EnrollType NVARCHAR(10)
        , RecordCount INT
        );    
    WITH    NetRecycle1
              AS ( SELECT  DISTINCT
                            BeginServiceDate
                          , 'BeginServiceMonth' = SUBSTRING(DATENAME(MONTH ,
                                                              [BeginServiceDate]) ,
                                                            1 , 3) + ' '
                            + DATENAME(YEAR , [BeginServiceDate])
                          , N.[YYYY-MM]
                          , EnrollType = 'Recycle1'
                          , 'Net_Recycle1' = COUNT(DISTINCT N.enroll_orig_transaction_id)
                   FROM     StreamInternal.dbo.[TX_Enroll_Recycle1] N
                   WHERE    [BeginServiceDate] >= @StartDate
                            AND [BeginServiceDate] <= @EndDate
                   GROUP BY DATENAME(MONTH , [BeginServiceDate]) + ' '
                            + DATENAME(YEAR , [BeginServiceDate])
                          , [BeginServiceDate]
                          , N.[YYYY-MM]
                 )
        INSERT  INTO #Net_Recycle1
                SELECT  BeginServiceDate
                      , 'MonthID' = [YYYY-MM]--DATEPART(MONTH , BeginServiceDate)
                      , BeginServiceMonth
                      , EnrollType
                      , 'Net_Recycle1' = SUM(Net_Recycle1)
                FROM    NetRecycle1
                GROUP BY BeginServiceDate
                      , BeginServiceMonth
                      , EnrollType
                      , [YYYY-MM]
                ORDER BY [BeginServiceDate]
     --SELECT 'MonthID' = [YYYY-MM]
     --     , 'Month' = BeginServiceMonth
     --     , 'NetAddition' = SUM(NetAddition)
     --FROM   Net_TOS
     --GROUP BY BeginServiceMonth
     --     , [YYYY-MM]
     --ORDER BY [YYYY-MM];
 
    --SELECT  *
    --FROM    #Net_Recycle1

------------------------------
--R2 (same esiid, enroll within 90days after drop)
-------------------------------
    IF OBJECT_ID(N'tempdb..#Net_Recycle2' , N'U') IS NOT NULL
        DROP TABLE #Net_Recycle2;
    CREATE TABLE #Net_Recycle2
        ( BeginServiceDate DATETIME
        , MonthID NVARCHAR(10)
        , BeginServiceMonth NVARCHAR(50)
        , EnrollType NVARCHAR(10)
        , RecordCount INT
        );    
    WITH    NetRecycle2
              AS ( SELECT  DISTINCT
                            BeginServiceDate
                          , 'BeginServiceMonth' = SUBSTRING(DATENAME(MONTH ,
                                                              [BeginServiceDate]) ,
                                                            1 , 3) + ' '
                            + DATENAME(YEAR , [BeginServiceDate])
                          , N.[YYYY-MM]
                          , EnrollType = 'Recycle2'
                          , 'Net_Recycle2' = COUNT(DISTINCT N.enroll_orig_transaction_id)
                   FROM     StreamInternal.dbo.[TX_Enroll_Recycle2] N
                   WHERE    [BeginServiceDate] >= @StartDate
                            AND [BeginServiceDate] <= @EndDate
                   GROUP BY DATENAME(MONTH , [BeginServiceDate]) + ' '
                            + DATENAME(YEAR , [BeginServiceDate])
                          , [BeginServiceDate]
                          , N.[YYYY-MM]
                 )
        INSERT  INTO #Net_Recycle2
                SELECT  BeginServiceDate
                      , 'MonthID' = [YYYY-MM]--DATEPART(MONTH , BeginServiceDate)
                      , BeginServiceMonth
                      , EnrollType
                      , 'Net_Recycle2' = SUM(Net_Recycle2)
                FROM    NetRecycle2
                GROUP BY BeginServiceDate
                      , BeginServiceMonth
                      , EnrollType
                      , [YYYY-MM]
                ORDER BY [BeginServiceDate]
     --SELECT 'MonthID' = [YYYY-MM]
     --     , 'Month' = BeginServiceMonth
     --     , 'NetAddition' = SUM(NetAddition)
     --FROM   Net_TOS
     --GROUP BY BeginServiceMonth
     --     , [YYYY-MM]
     --ORDER BY [YYYY-MM];
 
    --SELECT  *
    --FROM    #Net_Recycle2

---------------------------------
---- Get the Totals
---------------------------------  

    IF OBJECT_ID(N'tempdb..#MvInMvOt_Summary' , N'U') IS NOT NULL
        DROP TABLE #MvInMvOt_Summary;
    CREATE TABLE #MvInMvOt_Summary
        ( BeginServiceDate DATETIME
        , MonthID NVARCHAR(10)
        , BeginServiceMonth NVARCHAR(50)
        , EnrollType NVARCHAR(10)
        , RecordCount INT
        )
    INSERT  INTO #MvInMvOt_Summary
            SELECT  BeginServiceDate
                  , MonthID
                  , BeginServiceMonth
                  , EnrollType = 'Total'
                  , RecordCount
            FROM    #NetEnroll
            UNION ALL
            SELECT  BeginServiceDate
                  , MonthID
                  , BeginServiceMonth
                  , EnrollType = 'Total'
                  , RecordCount
            FROM    #Net_TOS
            UNION ALL
            SELECT  BeginServiceDate
                  , MonthID
                  , BeginServiceMonth
                  , EnrollType = 'Total'
                  , RecordCount
            FROM    #Net_Recycle1
            UNION ALL
            SELECT  BeginServiceDate
                  , MonthID
                  , BeginServiceMonth
                  , EnrollType = 'Total'
                  , RecordCount
            FROM    #Net_Recycle2
            ORDER BY MonthID
            

    --SELECT  *
    --FROM    #MvInMvOt_Summary


---------------------------------
---- Bring it all together
---------------------------------    
    SELECT  *
    FROM    #NetEnroll
    UNION ALL
    SELECT  *
    FROM    #Net_TOS
    UNION ALL
    SELECT  *
    FROM    #Net_Recycle1
    UNION ALL
    SELECT  *
    FROM    #Net_Recycle2
    UNION ALL
    SELECT  BeginServiceDate
          , MonthID
          , BeginServiceMonth
          , EnrollType
          , SUM(RecordCount)
    FROM    #MvInMvOt_Summary
    GROUP BY BeginServiceDate
          , MonthID
          , BeginServiceMonth
          , EnrollType
    ORDER BY MonthID
END




GO


