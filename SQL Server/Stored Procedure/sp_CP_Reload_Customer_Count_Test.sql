USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_CP_Reload_Customer_Count_Test]    Script Date: 08/25/2014 09:50:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
08/15/2014 				Jide Akintoye						Format Stored procedure




**********************************************************************************************/

CREATE PROCEDURE [dbo].[sp_CP_Reload_Customer_Count_Test]
AS
    BEGIN

---------------------------------------------
--seed calendar min and max date
---------------------------------------------
        SELECT  CalendarDate ,
                ROW_NUMBER() OVER ( PARTITION BY NULL ORDER BY CalendarDate ASC ) rowversion
        INTO    #cal
        FROM    calendar c
        WHERE   c.CalendarDate BETWEEN ( SELECT MIN(cc.BeginServiceDate)
                                         FROM   CustomerProfile_Test cc
                                       )
                               AND     ( SELECT MAX(mm.max)
                                         FROM   ( (SELECT   MAX(cc.BeginServiceDate) max
                                                   FROM     CustomerProfile_Test cc)
                                                  UNION
                                                  ( SELECT  MAX(cc.EndServiceDate)
                                                    FROM    CustomerProfile_Test cc
                                                  )
                                                ) mm
                                       )


---------------------------------------------
-- get distinct rows needed for each day (61 rows)
---------------------------------------------
        SELECT DISTINCT
                cp.Commodity ,
                cp.State ,
                cp.PremiseType ,
                cp.LDCName
        INTO    #dist
        FROM    CustomerProfile_Test cp
        WHERE   cp.BeginServiceDate IS NOT NULL

---------------------------------------------
--loop thru and create base table (3374 row(s) affected)
---------------------------------------------
        DECLARE @intFlag INT
        SET @intFlag = 1
        WHILE ( @intFlag <= ( SELECT    MAX(c.rowversion)
                              FROM      #cal c
                            ) )
            BEGIN
                PRINT @intFlag
   
                IF OBJECT_ID('tempdb..#tmp') IS NULL
                    ( SELECT    cp.Commodity ,
                                cp.State ,
                                cp.PremiseType ,
                                cp.LDCName ,
                                @intFlag AS rowno
                      INTO      #tmp
                      FROM      #dist cp		
	
	--SET @intFlag = @intFlag + 1
                    )
                ELSE
                    INSERT  INTO #tmp
                            ( Commodity ,
                              State ,
                              PremiseType ,
                              LDCName ,
                              rowno
                            )
                            ( SELECT    cp.Commodity ,
                                        cp.State ,
                                        cp.PremiseType ,
                                        cp.LDCName ,
                                        @intFlag AS rowno
                              FROM      #dist cp
                            )
                SET @intFlag = @intFlag + 1
            END
--GO


------------------------------------------
--create master table
------------------------------------------
        SELECT  t.* ,
                c.CalendarDate
        INTO    #mast
        FROM    #cal c
        LEFT JOIN #tmp t ON c.rowversion = t.rowno
        ORDER BY t.rowno


----------------------------------------------
--make sure no overlaps on start/end period 1752715
----------------------------------------------
        SELECT DISTINCT
                c.LDCNo ,
                c.State ,
                c.BeginServiceDate ,
                c.EndServiceDate ,
                c.LDCName ,
                c.PremiseType ,
                c.Commodity
--ROW_NUMBER() over(PARTITION by c.LDCNo, c.State, c.LDCName, c.PremiseType, c.Commodity order by c.BeginServiceDate, c.EndServiceDate asc) rowno,
--ROW_NUMBER() over(PARTITION by null order by c.LDCNo, c.State, c.LDCName, c.PremiseType, c.Commodity, c.BeginServiceDate, c.EndServiceDate asc) keyno
        INTO    #overlaptmp
        FROM    CustomerProfile_Test c
        WHERE   c.BeginServiceDate IS NOT NULL
                AND c.BeginServiceDate < ISNULL(c.EndServiceDate ,
                                                '12/31/2999')
                AND c.LDCNo IS NOT NULL
	  --and c.LDCNo = '1140408125-10443720003060513'
ORDER BY        c.LDCNo ,
                c.State ,
                c.LDCName ,
                c.PremiseType ,
                c.Commodity ,
                c.BeginServiceDate ,
                c.EndServiceDate
--drop table #overlaptmp


----------------------------------------------
--create key and rownum
----------------------------------------------
        SELECT DISTINCT
                c.LDCNo ,
                c.State ,
                c.BeginServiceDate ,
                c.EndServiceDate ,
                c.LDCName ,
                c.PremiseType ,
                c.Commodity ,
                ROW_NUMBER() OVER ( PARTITION BY c.LDCNo , c.State , c.LDCName ,
                                    c.PremiseType , c.Commodity ORDER BY c.BeginServiceDate, ISNULL(c.EndServiceDate ,
                                                              '12/31/2999') ASC ) rowno ,
                ROW_NUMBER() OVER ( PARTITION BY NULL ORDER BY c.LDCNo, c.State, c.LDCName, c.PremiseType, c.Commodity, c.BeginServiceDate, ISNULL(c.EndServiceDate ,
                                                              '12/31/2999') ASC ) keyno
        INTO    #CP_no_overlap
        FROM    #overlaptmp c 
--order by c.LDCNo, c.State, c.LDCName, c.PremiseType, c.Commodity, c.BeginServiceDate, isnull(c.EndServiceDate,'12/31/2999')
-- drop table #CP_no_overlap


----------------------------------------------
--candidates to be fixed due to overlap
----------------------------------------------
        SELECT DISTINCT
                a.BeginServiceDate AS NewEndDate ,
                b.*--, a.* --distinct a.LDCNo--, a.State, a.LDCName, a.PremiseType, a.Commodity
        INTO    #fixthis
        FROM    #CP_no_overlap a
        LEFT JOIN #CP_no_overlap b ON a.LDCNo = b.LDCNo
                                      AND ISNULL(a.Commodity , 'X') = ISNULL(b.Commodity ,
                                                              'X')
                                      AND ISNULL(a.LDCName , 'X') = ISNULL(b.LDCName ,
                                                              'X')
                                      AND ISNULL(a.PremiseType , 'X') = ISNULL(b.PremiseType ,
                                                              'X')
                                      AND ISNULL(a.State , 'X') = ISNULL(b.State ,
                                                              'X')
                                      AND a.rowno = b.rowno + 1
					   --and a.BeginServiceDate < b.EndServiceDate
					   --and a.BeginServiceDate <> b.BeginServiceDate
        WHERE   --a.LDCNo = '1140408125-10443720003060513' and --'1115256665-1008901010316673448100' and--'00000000000016088010' and --'3000197115-5926001028' and
                a.BeginServiceDate < ISNULL(b.EndServiceDate , '12/31/2999')
                AND a.rowno <> b.rowno
                AND ( a.BeginServiceDate <> b.BeginServiceDate
                      OR ISNULL(a.EndServiceDate , '12/31/2999') <> ISNULL(b.EndServiceDate ,
                                                              '12/31/2999')
                      OR a.Commodity <> b.Commodity
                      OR a.LDCName <> b.LDCName
                      OR a.PremiseType <> b.PremiseType
                      OR a.State <> b.State
                    )

--drop table #fixthis

        BEGIN TRAN
        UPDATE  o
        SET     o.EndServiceDate = f.NewEndDate
        FROM    #CP_no_overlap o
        JOIN    #fixthis f ON o.keyno = f.keyno
        COMMIT

        BEGIN TRAN
        DELETE  FROM #CP_no_overlap
        WHERE   BeginServiceDate = EndServiceDate
        COMMIT


--##############################################
--what else? no more overlap
        SELECT DISTINCT
                a.BeginServiceDate AS NewEndDate ,
                b.*--, a.* --distinct a.LDCNo--, a.State, a.LDCName, a.PremiseType, a.Commodity
        FROM    #CP_no_overlap a
        LEFT JOIN #CP_no_overlap b ON a.LDCNo = b.LDCNo
                                      AND ISNULL(a.Commodity , 'X') = ISNULL(b.Commodity ,
                                                              'X')
                                      AND ISNULL(a.LDCName , 'X') = ISNULL(b.LDCName ,
                                                              'X')
                                      AND ISNULL(a.PremiseType , 'X') = ISNULL(b.PremiseType ,
                                                              'X')
                                      AND ISNULL(a.State , 'X') = ISNULL(b.State ,
                                                              'X')
                                      AND a.rowno = b.rowno + 1
					   --and a.BeginServiceDate < b.EndServiceDate
					   --and a.BeginServiceDate <> b.BeginServiceDate
        WHERE   --a.LDCNo = '1140408125-10443720003060513' and --'1115256665-1008901010316673448100' and--'00000000000016088010' and --'3000197115-5926001028' and
                a.BeginServiceDate < ISNULL(b.EndServiceDate , '12/31/2999')
                AND a.rowno <> b.rowno
                AND ( a.BeginServiceDate <> b.BeginServiceDate
                      OR ISNULL(a.EndServiceDate , '12/31/2999') <> ISNULL(b.EndServiceDate ,
                                                              '12/31/2999')
                      OR a.Commodity <> b.Commodity
                      OR a.LDCName <> b.LDCName
                      OR a.PremiseType <> b.PremiseType
                      OR a.State <> b.State
                    )


------------------------------------------
--get enroll
------------------------------------------
        SELECT  COUNT(DISTINCT c.LDCNo) AS Gain ,
                c.State ,
                c.BeginServiceDate ,
                c.LDCName ,
                c.PremiseType ,
                c.Commodity
        INTO    #enroll
        FROM    #CP_no_overlap c
        WHERE   c.BeginServiceDate IS NOT NULL
        GROUP BY c.State ,
                c.BeginServiceDate ,
                c.LDCName ,
                c.PremiseType ,
                c.Commodity

--drop table #enroll

------------------------------------------
--get loss
------------------------------------------
        SELECT  COUNT(DISTINCT c.LDCNo) AS Loss ,
                c.State ,
                c.EndServiceDate ,
                c.LDCName ,
                c.PremiseType ,
                c.Commodity
        INTO    #loss
        FROM    #CP_no_overlap c
        WHERE   c.BeginServiceDate IS NOT NULL
        GROUP BY c.State ,
                c.EndServiceDate ,
                c.LDCName ,
                c.PremiseType ,
                c.Commodity

--drop table #loss

------------------------------------------
--stitch enroll and loss with mast
------------------------------------------
        SELECT  m.* ,
                ISNULL(e.Gain , 0) Gain ,
                ISNULL(l.Loss , 0) Loss
        INTO    #Custcnt
        FROM    #mast m
        LEFT JOIN #enroll e ON m.CalendarDate = e.BeginServiceDate
                               AND ISNULL(m.Commodity , 'X') = ISNULL(e.Commodity ,
                                                              'X')
                               AND ISNULL(m.LDCName , 'X') = ISNULL(e.LDCName ,
                                                              'X')
                               AND ISNULL(m.PremiseType , 'X') = ISNULL(e.PremiseType ,
                                                              'X')
                               AND ISNULL(m.State , 'X') = ISNULL(e.State ,
                                                              'X')
        LEFT JOIN #loss l ON m.CalendarDate = l.EndServiceDate + 1
                             AND ISNULL(m.Commodity , 'X') = ISNULL(l.Commodity ,
                                                              'X')
                             AND ISNULL(m.LDCName , 'X') = ISNULL(l.LDCName ,
                                                              'X')
                             AND ISNULL(m.PremiseType , 'X') = ISNULL(l.PremiseType ,
                                                              'X')
                             AND ISNULL(m.State , 'X') = ISNULL(l.State , 'X')
        ORDER BY m.CalendarDate	

--drop table #Custcnt

-----------------------------------------------------
--gets  results  
--insert data into CP_Customer_Count 

--*****Be sure to check for NULLS on Premise Type, LDC, etc.
----------------------------------------------------

        TRUNCATE TABLE  [StreamInternal].[dbo].[CP_Customer_Count_Test];

        INSERT  INTO [StreamInternal].[dbo].[CP_Customer_Count_Test]
                ( NetCount ,
                  GainCount ,
                  LossCount ,
                  CustCount ,
                  Commodity ,
                  LDCName ,
                  PremiseType ,
                  State ,
                  CalendarDate ,
                  DataSource ,
                  RecordDate ,
                  RecordCreatedBy ,
                  RecordLastUpdatedBy ,
                  RecordLastUpdatedDate
                )
                SELECT  SUM(c.Gain) - SUM(c.Loss) AS NetCount ,
                        SUM(c.Gain) AS GainCount ,
                        SUM(c.Loss) AS [LossCount] ,
                        ( SELECT    ( (SUM(cc.Gain) - SUM(cc.Loss)) )
                          FROM      #Custcnt cc
                          WHERE     ISNULL(cc.State , 'X') = ISNULL(c.State ,
                                                              'X')
                                    AND ISNULL(cc.LDCName , 'X') = ISNULL(c.LDCName ,
                                                              'X')
                                    AND ISNULL(cc.PremiseType , 'X') = ISNULL(c.PremiseType ,
                                                              'X')
                                    AND ISNULL(cc.Commodity , 'X') = ISNULL(c.Commodity ,
                                                              'X')
--and cc.rowno = (c.rowno-1)
                                    AND cc.CalendarDate <= CAST(c.CalendarDate AS DATE)
                        ) AS CustCount ,
                        c.Commodity ,
                        c.LDCName ,
                        c.PremiseType ,
                        c.State ,
                        c.CalendarDate ,
                        CASE WHEN c.State = 'TX' THEN 'CIS1'
                             WHEN c.State = 'GA' THEN 'CIS2'
                             WHEN c.State IN ( 'DC' , 'MD' , 'NJ' , 'NY' ,
                                               'PA' ) THEN 'ISTA'
                        END AS DataSource ,
                        CONVERT(DATETIME , GETDATE() , 120) AS RecordDate ,
                        'sp_CP_Customer_Count' AS RecordCreatedBy ,
                        'sp_CP_Customer_Count' AS RecordLastUpdatedBy ,
                        CONVERT(DATETIME , GETDATE() , 120) AS RecordLastUpdatedDate
                FROM    #Custcnt c -- where c.CalendarDate <= cast(getdate() as date) -- and c.State = 'TX' and c.LDCName = 'TNMP' --and c.PremiseType = 'R'
--and c.LDCNo = '3000242769-0138362739'
GROUP BY                c.Commodity ,
                        c.LDCName ,
                        c.PremiseType ,
                        c.State ,
                        c.CalendarDate
                ORDER BY c.State ,
                        c.LDCName ,
                        c.PremiseType ,
                        c.Commodity ,
                        c.CalendarDate



-- OLD
--INSERT INTO [StreamInternal].[dbo].[CP_Customer_Count]
--(
-- CustCount,
-- GainCount,
-- LossCount,
-- Commodity,
-- LDCName, 
-- PremiseType, 
-- State, 
-- CalendarDate,
-- DataSource,
-- RecordDate,
-- RecordCreatedBy,
-- RecordLastUpdatedBy,
-- RecordLastUpdatedDate
--)
--select 
--sum(c.Gain)- sum(c.Loss) as CustCnt,
--sum(c.Gain) as GainCount,
--sum(c.Loss) as [LossCount], 
--c.Commodity,
--c.LDCName, 
--c.PremiseType, 
--c.State, 
--c.CalendarDate,
--case when c.State = 'TX' then 'CIS1'
--	 when c.State = 'GA' then 'CIS2'
--	 when c.State in ('DC','MD','NJ','NY','PA') then 'ISTA' 
--end AS DataSource,
--CONVERT(DATETIME,GetDate(),120) as RecordDate,
--'sp_CP_Customer_Count' as RecordCreatedBy,
--'sp_CP_Customer_Count' as RecordLastUpdatedBy,
--CONVERT(DATETIME,GETDATE(),120) as RecordLastUpdatedDate
--from #Custcnt c -- where c.CalendarDate <= cast(getdate() as date) -- and c.State = 'TX' and c.LDCName = 'TNMP' --and c.PremiseType = 'R'
----and c.LDCNo = '3000242769-0138362739'
--group by c.Commodity, c.LDCName, c.PremiseType, c.State ,c.CalendarDate
--order by c.State, c.LDCName, c.PremiseType, c.Commodity ,c.CalendarDate

--select * from [StreamInternal].[dbo].[CP_Customer_Count]




-----------------------------------------------------
--drop tables  
----------------------------------------------------
        DROP TABLE #cal
        DROP TABLE #dist
        DROP TABLE #tmp
        DROP TABLE #mast
        DROP TABLE #overlaptmp
        DROP TABLE #CP_no_overlap
        DROP TABLE #enroll
        DROP TABLE #loss
        DROP TABLE #Custcnt



-----------------------------------------------------
--Send Email count  
----------------------------------------------------

        DECLARE @body VARCHAR(MAX)
        DECLARE @PassDate DATE

        SET @PassDate = GETDATE()

        CREATE TABLE #Temp
            ( [State] [VARCHAR](50) ,
              [Commodity] [VARCHAR](10) ,
              [CustCnt] [INT] ,
              [PrevOneDayGainCount] [INT] ,
              [PrevOneDayLossCount] [INT] ,
              [PrevOneDayNetCount] [INT] ,
              [MTDNetCount] [INT] ,
              [YTDNetCount] [INT]
            )

        INSERT  INTO #Temp
                SELECT  ( CASE WHEN c.State = 'TX' THEN 'Texas'
                               WHEN c.State = 'MD' THEN 'Maryland'
                               WHEN c.State = 'GA' THEN 'Georgia'
                               WHEN c.State = 'PA' THEN 'Pennsylvania'
                               WHEN c.State = 'NJ' THEN 'New Jersey'
                               WHEN c.State = 'NY' THEN 'New York'
                               WHEN c.State = 'DC' THEN 'Washington D.C. '
                          END ) AS State ,
                        c.Commodity ,
                        SUM(c.GainCount) - SUM(c.LossCount) AS CustCnt ,
                        ( SELECT    SUM(cc.GainCount)
                          FROM      [StreamInternal].[dbo].[CP_Customer_Count_Test] cc
                          WHERE     cc.CalendarDate = CAST(@PassDate AS DATE)
                                    AND ISNULL(cc.State , 'X') = ISNULL(c.State ,
                                                              'X')
                                    AND ISNULL(cc.Commodity , 'X') = ISNULL(c.Commodity ,
                                                              'X')
                        ) AS PrevOneDayGainCount ,
                        ( SELECT    SUM(c2.LossCount)
                          FROM      [StreamInternal].[dbo].[CP_Customer_Count_Test] c2
                          WHERE     c2.CalendarDate = CAST(@PassDate AS DATE)
                                    AND ISNULL(c2.State , 'X') = ISNULL(c.State ,
                                                              'X')
                                    AND ISNULL(c2.Commodity , 'X') = ISNULL(c.Commodity ,
                                                              'X')
                        ) AS PrevOneDayLossCount ,
                        ( SELECT    SUM(c3.NetCount)
                          FROM      [StreamInternal].[dbo].[CP_Customer_Count_Test] c3
                          WHERE     c3.CalendarDate = CAST(@PassDate AS DATE)
                                    AND ISNULL(c3.State , 'X') = ISNULL(c.State ,
                                                              'X')
                                    AND ISNULL(c3.Commodity , 'X') = ISNULL(c.Commodity ,
                                                              'X')
                        ) AS PrevOneDayNetCount ,
                        ( SELECT    SUM(c4.GainCount) - SUM(c4.LossCount)
                          FROM      [StreamInternal].[dbo].[CP_Customer_Count_Test] c4
                          WHERE     c4.CalendarDate >= CONVERT(VARCHAR(25) , DATEADD(dd ,
                                                              -( DAY(@PassDate)
                                                              - 1 ) ,
                                                              @PassDate) , 101)
                                    AND c4.CalendarDate <= GETDATE() --CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,@PassDate))),DATEADD(mm,1,@PassDate)),101)
                                    AND ISNULL(c4.State , 'X') = ISNULL(c.State ,
                                                              'X')
                                    AND ISNULL(c4.Commodity , 'X') = ISNULL(c.Commodity ,
                                                              'X')
                        ) AS MTDNetCount ,
                        ( SELECT    SUM(c5.GainCount) - SUM(c5.LossCount)
                          FROM      [StreamInternal].[dbo].[CP_Customer_Count_Test] c5
                          WHERE     c5.CalendarDate >= DATEADD(YEAR ,
                                                              DATEDIFF(YEAR ,
                                                              0 , @PassDate) ,
                                                              0)
                                    AND c5.CalendarDate <= GETDATE() --DATEADD(MILLISECOND, -3, DATEADD(YEAR, DATEDIFF(YEAR, 0, @PassDate) + 1, 0))
                                    AND ISNULL(c5.State , 'X') = ISNULL(c.State ,
                                                              'X')
                                    AND ISNULL(c5.Commodity , 'X') = ISNULL(c.Commodity ,
                                                              'X')
                        ) AS YTDNetCount
                FROM    [StreamInternal].[dbo].[CP_Customer_Count_Test] c
                WHERE   c.CalendarDate <= CAST(@PassDate AS DATE)
                GROUP BY c.State ,
                        c.Commodity 



        DECLARE @tableHTML NVARCHAR(MAX);

        SET @tableHTML = N'<head>'
            + N'<style type="text/css">h2, body {font-family: Arial, verdana;} table{font-size:11px; border-collapse:collapse;} td{background-color:#F1F1F1; border:1px solid black; padding:3px;} th{background-color:#99CCFF;}</style>'
            + N'</head>' + N'<body>' + N' <hr> ' + N' ' + N'<table>'
            + N'<caption><H1><font color="#0066FF" size="7">Customer Counts Report</H1>'
            + N'<H1>' + CAST(@PassDate AS NVARCHAR(25)) + N'</H1></caption>'
            + N'<table border="1">'
            + N'<tr><th>State</th><th>Commodity</th><th>  Customer Count  </th><th>  One Day Gain ESIIDs  </th><th>  One Day Lost ESIIDs  </th><th>  One Day Net ESIIDs  </th><th>  MTD Net ESIIDs  </th> '
            + N'<th>  YTD Net ESIIDs  </th></tr>'
            + CAST(( SELECT td = [State] ,
                            '' ,
                            td = [Commodity] ,
                            '' ,
                            td = [CustCnt] ,
                            '' ,
                            td = [PrevOneDayGainCount] ,
                            '' ,
                            td = [PrevOneDayLossCount] ,
                            '' ,
                            td = [PrevOneDayNetCount] ,
                            '' ,
                            td = [MTDNetCount] ,
                            '' ,
                            td = [YTDNetCount] ,
                            ''
                     FROM   #Temp
                     ORDER BY [State]
                   FOR
                     XML PATH('tr') ,
                         TYPE
                   ) AS NVARCHAR(MAX)) + N'</table>' + N'<br />'
            + --N'<table border="1">' +
      --N'<font color="#0066FF" size="3"><a href="'+ @link +'" target="_blank">Click here to See dashboard</a><br/><br/>' +
            N'<table>'
            + N'<caption><H1><font color="#0066FF" size="5">Summary</H1></caption>'
            + N'<table border="1">'
            + N'<tr><th>  Total MTD  </th><th>  Total YTD  </th>'
            + N'<th>Total Active</th></tr>'
            + CAST(( SELECT td = SUM([MTDNetCount]) ,
                            '' ,
                            td = SUM([YTDNetCount]) ,
                            '' ,
                            td = SUM([CustCnt]) ,
                            ''
                     FROM   #Temp
                   FOR
                     XML PATH('tr') ,
                         TYPE
                   ) AS NVARCHAR(MAX)) + N'</table>' 
    

        EXEC msdb.dbo.sp_send_dbmail @profile_name = 'SMTPRELAY01' ,
            @from_address = 'SSIS_AllData@streamenergy.net' ,
            @recipients = 'darren.williams@streamenergy.net;steve.nelson@streamenergy.net;mark.cheng@streamenergy.net;matt.baker@streamenergy.net' ,
            @subject = 'Customer Counts PEND TX TEST' , @body = @tableHTML ,
            @body_format = 'HTML';

        DROP TABLE #Temp


--CREATE TABLE #Temp 
--( 
--  [State]  [varchar] (2),
--  [Commodity]  [varchar] (10),
--  [CustCnt] [int],
--  [PrevOneDayGainCount] [int],
--  [PrevOneDayLossCount] [int],
--  [PrevOneDayNetCount] [int],
--  [MTDNetCount] [int],
--  [YTDNetCount] [int]
--)

--INSERT INTO #Temp

--			select 
--			c.State,
--			c.Commodity,
--			sum(c.GainCount)- sum(c.LossCount) as CustCnt,
--			(select sum(cc.GainCount) from [StreamInternal].[dbo].[CP_Customer_Count] cc
--			where cc.CalendarDate = cast(@PassDate as date) and isnull(cc.State,'X') = isnull(c.State,'X') 
--			and isnull(cc.Commodity,'X') = isnull(c.Commodity,'X') 
--			) as PrevOneDayGainCount ,
--			(select sum(c2.LossCount) from [StreamInternal].[dbo].[CP_Customer_Count] c2
--			where c2.CalendarDate = cast(@PassDate as date) and isnull(c2.State,'X') = isnull(c.State,'X')
--			and isnull(c2.Commodity,'X') = isnull(c.Commodity,'X') 
--			) as PrevOneDayLossCount,
--			(select sum(c3.NetCount) from [StreamInternal].[dbo].[CP_Customer_Count] c3
--			where c3.CalendarDate = cast(@PassDate as date) and isnull(c3.State,'X') = isnull(c.State,'X')
--			and isnull(c3.Commodity,'X') = isnull(c.Commodity,'X') 
--			) as PrevOneDayNetCount,
--			(select sum(c4.GainCount) - sum(c4.LossCount) from [StreamInternal].[dbo].[CP_Customer_Count] c4
--			where c4.CalendarDate >= CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(@PassDate)-1),@PassDate),101)
--			and c4.CalendarDate <= GetDate() --CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,@PassDate))),DATEADD(mm,1,@PassDate)),101)
--			and isnull(c4.State,'X') = isnull(c.State,'X') and isnull(c4.Commodity,'X') = isnull(c.Commodity,'X') 
--			) as MTDNetCount,
--			(select sum(c5.GainCount) - sum(c5.LossCount) from [StreamInternal].[dbo].[CP_Customer_Count] c5
--			where c5.CalendarDate >= DATEADD(YEAR, DATEDIFF(YEAR, 0, @PassDate), 0)
--			and c5.CalendarDate <= GetDate() --DATEADD(MILLISECOND, -3, DATEADD(YEAR, DATEDIFF(YEAR, 0, @PassDate) + 1, 0))
--			and isnull(c5.State,'X') = isnull(c.State,'X') and isnull(c5.Commodity,'X') = isnull(c.Commodity,'X') 
--			) as YTDNetCount
--			from [StreamInternal].[dbo].[CP_Customer_Count] c
--			where c.CalendarDate <= cast(@PassDate as date)
--			group by  c.State , c.Commodity 

--            --select 
--            --c.State,
--            --c.Commodity,
--            --sum(c.GainCount)- sum(c.LossCount) as CustCnt,
--            --(select sum(cc.GainCount) from [StreamInternal].[dbo].[CP_Customer_Count] cc
--            --where cc.CalendarDate = cast(@PassDate as date) and isnull(cc.State,'X') = isnull(c.State,'X')
--            --) as PrevOneDayGainCount ,
--            --(select sum(c2.LossCount) from [StreamInternal].[dbo].[CP_Customer_Count] c2
--            --where c2.CalendarDate = cast(@PassDate as date) and isnull(c2.State,'X') = isnull(c.State,'X')
--            --) as PrevOneDayLossCount,
--            --(select sum(c3.NetCount) from [StreamInternal].[dbo].[CP_Customer_Count] c3
--            --where c3.CalendarDate = cast(@PassDate as date) and isnull(c3.State,'X') = isnull(c.State,'X')
--            --) as PrevOneDayNetCount,
--            --(select sum(c4.GainCount) - sum(c4.LossCount) from [StreamInternal].[dbo].[CP_Customer_Count] c4
--            --where c4.CalendarDate >= CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(@PassDate)-1),@PassDate),101)
--            --and c4.CalendarDate <= GetDate() --CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,@PassDate))),DATEADD(mm,1,@PassDate)),101)
--            --and isnull(c4.State,'X') = isnull(c.State,'X')
--            --) as MTDNetCount,
--            --(select sum(c5.GainCount) - sum(c5.LossCount) from [StreamInternal].[dbo].[CP_Customer_Count] c5
--            --where c5.CalendarDate >= DATEADD(YEAR, DATEDIFF(YEAR, 0, @PassDate), 0)
--            --and c5.CalendarDate <= GetDate() --DATEADD(MILLISECOND, -3, DATEADD(YEAR, DATEDIFF(YEAR, 0, @PassDate) + 1, 0))
--            --and isnull(c5.State,'X') = isnull(c.State,'X')
--            --) as YTDNetCount

--            --from [StreamInternal].[dbo].[CP_Customer_Count] c
--            --where c.CalendarDate <= cast(@PassDate as date)
--            --group by  c.State, c.Commodity  -- c.Commodity,c.LDCName, c.PremiseType, 
--            ----order by c.State 


--DECLARE @tableHTML  NVARCHAR(MAX) ;

--SET @tableHTML =
--      N'<table>' +
--      N'<caption><H1>Customer Counts Report</H1>'+
--      N'<H1>'+CAST(@PassDate AS NVARCHAR(25))+
--      N'</H1></caption>' +
--      N'<table border="1">' +
--      N'<tr><th>State</th><th>Commodity</th><th>CustCnt</th><th>PrevOneDayGainCount</th><th>PrevOneDayLossCount</th><th>PrevOneDayNetCount</th><th>MTDNetCount</th> ' +
--    N'<th>YTDNetCount</th></tr>' +
--    CAST ( (  select td = [State],'', 
--							  td = [Commodity],'',
--                              td = [CustCnt], '', 
--                              td = [PrevOneDayGainCount], '',
--                              td = [PrevOneDayLossCount], '',
--                              td = [PrevOneDayNetCount], '',
--                              td = [MTDNetCount], '',
--                              td = [YTDNetCount], ''
--                        FROM  #Temp ORDER BY [State]
                  
--              FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +
--    N'</table>' +
    
--      N'<br><br><br>' +
--      N'<table>' +
--      N'<caption><H1>Summary</H1></caption>' +
--      N'<table border="1">' +
--      N'<tr><th>Total MTD</th><th>Total YTD</th>' +
--    N'<th>Total Active</th></tr>' +              
--    CAST ( (  select td = sum([MTDNetCount]),'', 
--                              td = SUM([YTDNetCount]), '', 
--                              td = SUM([CustCnt]), ''
--                        FROM  #Temp  
--              FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +
--    N'</table>' 
    

--EXEC msdb.dbo.sp_send_dbmail 
--@profile_name ='SMTPRELAY01',
--@from_address = 'SSIS_AllData@streamenergy.net',
--@recipients ='darren.williams@streamenergy.net;steve.nelson@streamenergy.net;mark.cheng@streamenergy.net;matt.baker@streamenergy.net',
--@subject = 'Customer Counts',
--@body = @tableHTML,
--@body_format = 'HTML' ;

--DROP TABLE #Temp


    END


















GO


