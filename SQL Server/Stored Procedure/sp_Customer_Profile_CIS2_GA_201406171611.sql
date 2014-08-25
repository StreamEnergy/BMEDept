USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_Customer_Profile_CIS2_GA_201406171611]    Script Date: 08/25/2014 09:51:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
02/17/2014				Darren Williams						This SP is for the GA Customer Profile.  
02/17/2014				Darren Williams						Initial Release [sp_Customer_Profile_Load_CIS2_GA] .
02/27/2014				Matt Baker							Draft version.						
03/23/2014				Mark Cheng							Alter scenarios 4 and 5.
03/24/2014				Matt Baker							Cleanup stored procedure.
08/15/2014 				Jide Akintoye						Format Stored procedure




**********************************************************************************************/


CREATE PROCEDURE [dbo].[sp_Customer_Profile_CIS2_GA_201406171611]
AS
    PRINT 'Drop Tables'
    DROP TABLE #cis2
    DROP TABLE #scenario1
    DROP TABLE #scenario2
    DROP TABLE #scenario3
    DROP TABLE #scenario4
    DROP TABLE #scenario5
--drop table #scenario6
--drop table #testcustomerprofile

----For test purposes use this as the source data.
--Print 'Create test table'
--select 
--* 
--into 
--#testcustomerprofile 
--from 
--StreamInternal.dbo.CustomerProfile

--Grab source data.
    PRINT 'Isolate CIS2 Data'
    SELECT  c.* ,
            NULL AS scenario
    INTO    #cis2
    FROM    CustomerProfile c
    WHERE   c.DataSource = 'CIS2'

--Analyze scenario #1 update endservicedate using beginservicedate
    PRINT 'Calculate scenario 1'
    SELECT  c.LDCNo ,
            c.BeginServiceDate ,
            c.EndServiceDate ,
            v.FIRSTREAD ,
            v.LASTREAD ,
            v.FIRSTCONS ,
            v.LASTCONS ,
            v.HASFINALUSAGE ,
            DATEDIFF(DAY , c.BeginServiceDate , GETDATE()) diff
    INTO    #scenario1
    FROM    #cis2 c
    FULL OUTER JOIN CustomerProfile_GA_TransData_v v ON c.LDCNo = v.LDC_ACCOUNT_NUMBER
    WHERE   c.BeginServiceDate IS NOT NULL
            AND v.FIRSTCONS IS NULL
            AND DATEDIFF(DAY , c.BeginServiceDate , GETDATE()) > 45
            AND DATEDIFF(DAY , ISNULL(v.LASTREAD , '1/1/2000') , GETDATE()) > 45
            AND c.scenario IS NULL
    ORDER BY DATEDIFF(DAY , c.BeginServiceDate , GETDATE())

--Update affected entries for scenario 1
    PRINT 'Update scenario 1 to temp table'
    BEGIN TRAN
    UPDATE  c
    SET     c.EndServiceDate = s.BeginServiceDate ,
            c.scenario = '1'
    FROM    #cis2 c
    JOIN    #scenario1 s ON c.LDCNo = s.LDCNo
    COMMIT

--Analyze scenario #2 customers that are probably not active.
    PRINT 'Calculate scenario 2'
    SELECT  c.LDCNo ,
            v.LDC_ACCOUNT_NUMBER ,
            c.BeginServiceDate ,
            c.EndServiceDate ,
            v.FIRSTREAD ,
            v.LASTREAD ,
            v.FIRSTCONS ,
            v.LASTCONS ,
            v.HASFINALUSAGE ,
            c.scenario ,
            DATEDIFF(DAY , v.LASTREAD , GETDATE()) diff
    INTO    #scenario2
    FROM    #cis2 c
    FULL OUTER JOIN CustomerProfile_GA_TransData_v v ON c.LDCNo = v.LDC_ACCOUNT_NUMBER
    WHERE   GETDATE() BETWEEN c.BeginServiceDate
                      AND     ISNULL(c.EndServiceDate , '12/31/2999')
            AND DATEDIFF(DAY , v.LASTREAD , GETDATE()) > 31
            AND v.HASFINALUSAGE = '1'
            AND c.scenario IS NULL
    ORDER BY DATEDIFF(DAY , v.LASTREAD , GETDATE())

--Update affected entries for scenario 2
    PRINT 'Update scenario 2 to temp table'
    BEGIN TRAN
    UPDATE  c
    SET     c.EndServiceDate = s.LASTCONS ,
            c.scenario = '2'
    FROM    #cis2 c
    JOIN    #scenario2 s ON c.LDCNo = s.LDCNo
    COMMIT

--Analyze scenario #3.  Multi scenario sort.
    PRINT 'Calculate scenario 3'
    SELECT  c.LDCNo ,
            v.LDC_ACCOUNT_NUMBER ,
            c.BeginServiceDate ,
            c.EndServiceDate ,
            v.FIRSTREAD ,
            v.LASTREAD ,
            v.FIRSTCONS ,
            v.LASTCONS ,
            v.HASFINALUSAGE ,
            c.scenario ,
            DATEDIFF(DAY , v.LASTREAD , GETDATE()) diff
    INTO    #scenario3
    FROM    #cis2 c
    FULL OUTER JOIN CustomerProfile_GA_TransData_v v ON c.LDCNo = v.LDC_ACCOUNT_NUMBER
    WHERE   GETDATE() BETWEEN c.BeginServiceDate
                      AND     ISNULL(c.EndServiceDate , '12/31/2999')
            AND v.LASTREAD IS NULL
            AND DATEDIFF(DAY , c.BeginServiceDate , GETDATE()) > '45'
            AND c.scenario IS NULL

--Update affected entries for scenario 3
    PRINT 'Update scenario 3 to temp table'
    BEGIN TRAN
    UPDATE  c
    SET     c.EndServiceDate = s.LASTCONS ,
            c.scenario = '3'
    FROM    #cis2 c
    JOIN    #scenario3 s ON c.LDCNo = s.LDCNo
    COMMIT

/*
--Analyze scenario #4.  End Service Date Fix.  Issues with Begin Service Date Fix.
Print 'Calculate scenario 4'
select 
c.LDCNo, 
v.LDC_ACCOUNT_NUMBER, 
--c.BeginServiceDate, 
case 
	--when HASFINALUSAGE = '0' and v.LASTREAD IS null and LASTCONS IS null and EndServiceDate IS null and lastenddate is not null then LASTENDDATE
	when HASFINALUSAGE = '0' then null 
	when HASFINALUSAGE = '1' and LASTCONS IS not null then LASTCONS
	when HASFINALUSAGE = '1' and LASTCONS IS null and LASTREAD IS not null then LASTREAD
	when v.LASTREAD - v.FIRSTREAD <= 2 then v.LASTCONS
	--when v.LASTREAD IS null then v.LASTCONS
	--when v.LASTCONS is null and v.LASTREAD IS null then v.LASTCONS
	else
	null end as EndServiceDate, 
v.FIRSTREAD, 
v.LASTREAD,
v.FIRSTCONS, 
v.LASTCONS, 
v.LASTENDDATE,
v.HASFINALUSAGE, 
c.scenario, 
datediff(day, c.BeginServiceDate, GETDATE()) diff
--into #scenario4
from #cis2 c
full outer join CustomerProfile_GA_TransData_v v on c.LDCNo = v.LDC_ACCOUNT_NUMBER
where 
c.BeginServiceDate is null 
--and 
--v.FIRSTCONS is not null
and
c.scenario is null
and c.LDCNo is not null
--scenario below
--and HASFINALUSAGE = '0' and v.LASTREAD IS null and LASTCONS IS null and EndServiceDate IS null and lastenddate is not null
and HASFINALUSAGE = '0'
and HASFINALUSAGE = '1' and LASTCONS IS not null
and HASFINALUSAGE = '1' and LASTCONS IS null and LASTREAD IS not null
and v.LASTREAD - v.FIRSTREAD <= 2

select * from CustomerProfile_GA_TransData_v v where v.LDC_ACCOUNT_NUMBER = '00000000009100787352'

--Update affected entries for scenario 4
Print 'Update scenario 4 to temp table'
begin tran
update 
c 
set 
c.EndServiceDate = s.EndServiceDate, 
--c.BeginServiceDate = s.BeginServiceDate,
c.scenario = '4' 
from #cis2 c 
join #scenario4 s on c.LDCNo = s.LDCNo
commit
rollback
*/

--Analyze scenario #4.  Begin Service Date Fix.  Issues with Begin Service Date Fix.
    PRINT 'Calculate scenario 4'
    SELECT  c.LDCNo ,
            v.LDC_ACCOUNT_NUMBER ,
            v.FIRSTREAD AS BeginServiceDate ,
            v.LASTREAD AS EndServiceDate ,
            v.FIRSTREAD ,
            v.LASTREAD ,
            v.FIRSTCONS ,
            v.LASTCONS ,
            v.HASFINALUSAGE ,
            c.scenario ,
            DATEDIFF(DAY , c.BeginServiceDate , GETDATE()) diff
    INTO    #scenario4
    FROM    #cis2 c
    FULL OUTER JOIN CustomerProfile_GA_TransData_v v ON c.LDCNo = v.LDC_ACCOUNT_NUMBER
    WHERE   c.BeginServiceDate IS NULL
            AND FIRSTCONS IS NULL
            AND FIRSTREAD IS NOT NULL
            AND c.LDCNo IS NOT NULL
            AND DATEDIFF(DAY , v.LASTREAD , GETDATE()) > 31
    ORDER BY v.LASTREAD



--Update affected entries for scenario 4
    PRINT 'Update scenario 4 to temp table'
    BEGIN TRAN
    UPDATE  c
    SET     c.BeginServiceDate = s.BeginServiceDate ,
            c.EndServiceDate = s.EndServiceDate ,
            c.scenario = '4'
    FROM    #cis2 c
    JOIN    #scenario4 s ON c.LDCNo = s.LDCNo
    COMMIT
--rollback
--===========================================================================

--Analyze scenario #5.  Begin Service Date Fix.  Issues with Begin Service Date Fix.
    PRINT 'Calculate scenario 5'
    SELECT  c.LDCNo ,
            v.LDC_ACCOUNT_NUMBER ,
            FIRSTCONS AS BeginServiceDate ,
            CASE WHEN v.HASFINALUSAGE = '1' THEN v.LASTCONS
                 WHEN v.HASFINALUSAGE <> '1'
                      AND DATEDIFF(DAY , v.LASTREAD , GETDATE()) > 31
                 THEN v.LASTCONS
                 WHEN v.HASFINALUSAGE <> '1'
                      AND DATEDIFF(DAY , v.LASTCONS , GETDATE()) > 45
                      AND v.LASTREAD IS NULL THEN v.LASTCONS
            END AS EndServiceDate ,
            v.FIRSTREAD ,
            v.LASTREAD ,
            v.FIRSTCONS ,
            v.LASTCONS ,
            v.HASFINALUSAGE ,
            c.scenario ,
            DATEDIFF(DAY , c.BeginServiceDate , GETDATE()) diff
    INTO    #scenario5
    FROM    #cis2 c
    FULL OUTER JOIN CustomerProfile_GA_TransData_v v ON c.LDCNo = v.LDC_ACCOUNT_NUMBER
    WHERE   c.BeginServiceDate IS NULL
            AND FIRSTCONS IS NOT NULL
            AND c.LDCNo IS NOT NULL
    ORDER BY v.LASTCONS



--Update affected entries for scenario 5
    PRINT 'Update scenario 5 to temp table'
    BEGIN TRAN
    UPDATE  c
    SET     c.BeginServiceDate = s.BeginServiceDate ,
            c.EndServiceDate = s.EndServiceDate ,
            c.scenario = '5'
    FROM    #cis2 c
    JOIN    #scenario5 s ON c.LDCNo = s.LDCNo
    COMMIT
--rollback

---Analyze scenario #6. (not needed for now)
--select v.LASTREAD, c.*
--from #cis2 c
--full outer join CustomerProfile_GA_TransData_v v on c.LDCNo = v.LDC_ACCOUNT_NUMBER
--where datediff(day,c.EndServiceDate, v.LASTREAD) > '60'
--order by v.LASTREAD desc

/*
--*************************************
--ran on 2/21
--*************************************
--drop table #fdcg,#GAonflow 
-- FDCG 3/1/2014 = 38,440  4/1=(38502 row(s) affected)
select * into #fdcg 
from CustomerProfile_GA_TransData_v v where v.LASTREAD = '4/1/2014'
--(38498 row(s) affected)  4/1=(38512 row(s) affected)
select * into #GAonflow from #cis2 c
where '4/1/2014' between c.BeginServiceDate and ISNULL(c.EndServiceDate,'12/31/2999')
--drop table #GAonflow

select * from #cis2 c where c.LDCNo in
(
select g.LDCNo--f.LDC_ACCOUNT_NUMBER--g.LDCNo 
from #GAonflow g
full outer join #fdcg f on g.LDCNo = f.LDC_ACCOUNT_NUMBER
where 
--g.LDCNo is null --> (99 row(s) affected) 4/1=(153 row(s) affected)
f.LDC_ACCOUNT_NUMBER is null -->(157 row(s) affected)
--order by g.BeginServiceDate --f.FIRSTREAD, f.FIRSTCONS
) order by c.BeginServiceDate

select * from CustomerProfile c where c.LDCNo = '00000000006393724524'
select * from CustomerProfile_GA_TransData_v v where v.LDC_ACCOUNT_NUMBER = '00000000006393724524'
*/

--****** MARKC TODO: SCENARIO 6 (not needed for now)********************
--Analyze scenario #6.  Fix for burping customers
--Print 'Calculate scenario 6'
--select 
--c.LDCNo, 
--v.LDC_ACCOUNT_NUMBER,
--c.PremStatusID, 
----c.BeginServiceDate,
----c.EndServiceDate,
--case 
----when c.BeginServiceDate IS null and LASTREAD = FIRSTREAD then FIRSTREAD 
--when c.BeginServiceDate IS not null then c.BeginServiceDate
----else v.FIRSTCONS 
--end as BeginServiceDate,
----case 
----when c.EndServiceDate IS null and LASTREAD = FIRSTREAD then LASTREAD 
----when c.EndServiceDate IS not null then c.EndServiceDate
----else v.LASTCONS 
----end as EndServiceDate,
--c.EndServiceDate,
--v.FIRSTREAD, 
--v.LASTREAD,
--v.FIRSTCONS, 
--v.LASTCONS, 
--v.HASFINALUSAGE, 
--c.scenario, 
--datediff(day, c.BeginServiceDate, GETDATE()) diff
----into #scenario6
--from #cis2 c
--full outer join CustomerProfile_GA_TransData_v v on c.LDCNo = v.LDC_ACCOUNT_NUMBER
--where 
--c.EndServiceDate is null 
--and 
--c.BeginServiceDate is not null 
--and 
--c.PremStatusID not like '04%' 
--and 
--c.PremStatusID not like '03%'
----and
----c.scenario is null
--order by c.BeginServiceDate



----Update affected entries for scenario 6
--Print 'Update scenario 6 to temp table'
--begin tran
--update 
--c 
--set 
--c.BeginServiceDate = s.BeginServiceDate,
--c.EndServiceDate = s.EndServiceDate,
--c.scenario = '6' 
--from #cis2 c 
--join #scenario6 s on c.LDCNo = s.LDCNo



----Remove unaffected data from #cis2
--Print 'Delete unmodified data from working table'
--begin tran
--delete 
--from
--#cis2 
--where scenario is null
--commit

    PRINT 'Make time variable'
    DECLARE @vStamp DATETIME
    SET @vStamp = GETDATE()

--Update all scenarios from the staging table #cis2 to the customer profile table
    PRINT 'Post scenario 1 into main data'
    BEGIN TRAN
    UPDATE  c
    SET     c.EndServiceDate = u.EndServiceDate ,
            c.RecordLastUpdatedBy = 'sp_Customer_Profile_Load_CIS2_GA' ,
            c.RecordLastUpdatedDate = @vStamp
    FROM    #cis2 u
    JOIN    customerprofile c ON c.CustProfileID = u.CustProfileID
    WHERE   u.scenario = '1'
    COMMIT

    PRINT 'Post scenario 2 into main data'
    BEGIN TRAN
    UPDATE  c
    SET     c.EndServiceDate = u.EndServiceDate ,
            c.RecordLastUpdatedBy = 'sp_Customer_Profile_Load_CIS2_GA' ,
            c.RecordLastUpdatedDate = @vStamp
    FROM    #cis2 u
    JOIN    customerprofile c ON c.CustProfileID = u.CustProfileID
    WHERE   u.scenario = '2'
    COMMIT

    PRINT 'Post scenario 3 into main data'
    BEGIN TRAN
    UPDATE  c
    SET     c.EndServiceDate = u.EndServiceDate ,
            c.RecordLastUpdatedBy = 'sp_Customer_Profile_Load_CIS2_GA' ,
            c.RecordLastUpdatedDate = @vStamp
    FROM    #cis2 u
    JOIN    customerprofile c ON c.CustProfileID = u.CustProfileID
    WHERE   u.scenario = '3'
    COMMIT

    PRINT 'Post scenario 4 into main data'
    BEGIN TRAN
    UPDATE  c
    SET     c.EndServiceDate = u.EndServiceDate ,
            c.BeginServiceDate = u.BeginServiceDate ,
            c.RecordLastUpdatedBy = 'sp_Customer_Profile_Load_CIS2_GA' ,
            c.RecordLastUpdatedDate = @vStamp
    FROM    #cis2 u
    JOIN    customerprofile c ON c.CustProfileID = u.CustProfileID
    WHERE   u.scenario = '4'
    COMMIT

    PRINT 'Post scenario 5 into main data'
    BEGIN TRAN
    UPDATE  c
    SET     c.EndServiceDate = u.EndServiceDate ,
            c.BeginServiceDate = u.BeginServiceDate ,
            c.RecordLastUpdatedBy = 'sp_Customer_Profile_Load_CIS2_GA' ,
            c.RecordLastUpdatedDate = @vStamp
    FROM    #cis2 u
    JOIN    customerprofile c ON c.CustProfileID = u.CustProfileID
    WHERE   u.scenario = '5'
    COMMIT

--Print 'Post scenario 6 into main data'
--begin tran
--update c
--set 
--c.EndServiceDate = u.EndServiceDate,
--c.BeginServiceDate = u.BeginServiceDate,
--c.RecordLastUpdatedBy = 'sp_Customer_Profile_Load_CIS2_GA',
--c.RecordLastUpdatedDate = @vStamp
--from 
--#cis2 u
--join #testcustomerprofile c on c.CustProfileID = u.CustProfileID
--where u.scenario = '6'

--Print 'Review summarized output'
--select 
--c.RecordLastUpdatedBy,
--c.RecordLastUpdatedDate,
--COUNT(c.CustProfileID)
--from #testcustomerprofile c 
--where
--c.DataSource = 'Cis2'
--group by
--c.RecordLastUpdatedBy,
--c.RecordLastUpdatedDate

--select 
--c.LDCNo, 
--v.LDC_ACCOUNT_NUMBER, 
--c.BeginServiceDate, 
--c.EndServiceDate, 
--v.FIRSTREAD, 
--v.LASTREAD,
--v.FIRSTCONS, 
--v.LASTCONS, 
--v.HASFINALUSAGE, 
--c.scenario, 
--datediff(day, c.BeginServiceDate, GETDATE()) diff
--from #cis2 c
----left join 
--full outer join 
--CustomerProfile_GA_TransData_v v on c.LDCNo = v.LDC_ACCOUNT_NUMBER
--where 
--c.BeginServiceDate is null 
--and
--LDCNo is not null
--and
--scenario is not null
----and 
----(v.FIRSTCONS is not null or v.FIRSTREAD is not null)
----and
----LEFT(c.PremStatusID,2) not in ('01','02','03','05')

--select * from customerprofile where RecordLastUpdatedBy = 'sp_Customer_Profile_Load_CIS2_GA'

--select 
--* 
--from 
--#testcustomerprofile c  
--full outer join CustomerProfile_GA_TransData_v v on c.LDCNo = v.LDC_ACCOUNT_NUMBER 
--where 
--DataSource = 'Cis2' 
--and 
--BeginServiceDate is null 
--and 
--LDCNo is not null 
--and (FIRSTREAD is not null or FIRSTCONS is not null or FIRSTSTARTDATE is not null)
--order by c.RecordLastUpdatedBy 

--select distinct PremStatusID,PremStatus,COUNT(*) from #testcustomerprofile where DataSource = 'Cis2' and LDCNo is not null and BeginServiceDate is null group by PremStatusID,PremStatus order by PremStatusID

--select COUNT(*) as CustomerProfile_Null_Begin from StreamInternal.dbo.CustomerProfile c where c.DataSource = 'Cis2' and BeginServiceDate is null
--select COUNT(*) as Test_CustomerProfile_Null_Begin from #testcustomerprofile c where c.DataSource = 'Cis2' and BeginServiceDate is null
--select COUNT(*) as Modified_CustomerProfile_Null_Begin from #cis2 c where c.DataSource = 'Cis2' and BeginServiceDate is null

--select COUNT(*) as CustomerProfile_Null_End from StreamInternal.dbo.CustomerProfile c where c.DataSource = 'Cis2' and EndServiceDate is null
--select COUNT(*) as Test_CustomerProfile_Null_End from #testcustomerprofile c where c.DataSource = 'Cis2' and EndServiceDate is null
--select COUNT(*) as Modified_CustomerProfile_Null_End from #cis2 c where c.DataSource = 'Cis2' and EndServiceDate is null

--select COUNT(LDCNo) as ActiveLDCCount from #testcustomerprofile where DataSource = 'Cis2' and GETDATE() between BeginServiceDate and isnull(EndServiceDate,'12/31/2999')

--select * from #cis2 c where c.EndServiceDate is null and c.BeginServiceDate is not null and c.PremStatusID not like '04%' and c.PremStatusID not like '03%' order by BeginServiceDate



GO


