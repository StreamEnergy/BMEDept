USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_Customer_Profile_Load_CIS2_GA_Backup]    Script Date: 08/25/2014 09:53:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date				Author								Description
02/17/2014			Darren, Williams					This SP is for the GA Customer Profile.  
02/17/2014			Darren Williams						Initial Release [sp_Customer_Profile_Load_CIS2_GA] .						
3/14/2014			Darren Williams						Added transaction and email for validation		
08/15/2014 			Jide Akintoye						Format Stored procedure
		   
						   
**********************************************************************************************/




CREATE PROCEDURE [dbo].[sp_Customer_Profile_Load_CIS2_GA_Backup]
AS
    BEGIN



----------------------------------
-- Put SQL for GA here
----------------------------------

        SELECT TOP 3
                *
        FROM    [StreamInternal].[dbo].[CustomerProfile]
        WHERE   State = 'GA'


	
---------------------------------
--	Validate data, if bad send email
---------------------------------	
        DECLARE @tableHTML NVARCHAR(MAX);
        DECLARE @RecordDate AS DATE;
		
        SET @RecordDate = CONVERT(VARCHAR(10) , ( SELECT    MIN(RecordDate)
                                                  FROM      [StreamInternal].[dbo].CustomerProfile
                                                  WHERE     [DataSource] = 'CIS2'
                                                ) , 110);

        IF @RecordDate < CONVERT(VARCHAR(10) , GETDATE() , 110)
            BEGIN
                SET @tableHTML = N'<br>'
                    + N'The Customer Profile for GA does not have latest data, please check in the sp_Customer_Profile_Load_CIS2_GA or in SSIS - LoadCustomerProfile'
                    + N'GA data is more than 1 day old.  It should only be reloaded with the current date.'
                    + N'<br><br><br>' + N'<table>'
                    + N'<caption><H1>Counts Report</H1></caption>'
                    + N'<table border="1">'
                    + N'<tr><th>Counts</th><th>RecordDate</th>'
                    + N'<th>DataSource</th><th>RecordCreatedBy</th></tr>'
                    + CAST(( SELECT td = COUNT(*) ,
                                    '' ,
                                    td = c.RecordDate ,
                                    '' ,
                                    td = c.DataSource ,
                                    '' ,
                                    td = c.RecordCreatedBy ,
                                    ''
                             FROM   StreamInternal.dbo.CustomerProfile c
                             WHERE  [DataSource] = 'CIS2'
                             GROUP BY c.DataSource ,
                                    c.RecordDate ,
                                    c.RecordCreatedBy
                           FOR
                             XML PATH('tr') ,
                                 TYPE
                           ) AS NVARCHAR(MAX)) + N'</table>';

                EXEC msdb.dbo.sp_send_dbmail @profile_name = 'SMTPRELAY01' ,
                    @from_address = 'LoadCustomerProfile@streamenergy.net' ,
                    @recipients = 'darren.williams@streamenergy.net;steve.nelson@streamenergy.net;mark.cheng@streamenergy.net;matt.baker@streamenergy.net' ,
                    @subject = 'Error in Customer Profile for GA' ,
                    @body = @tableHTML , @body_format = 'HTML';
            END


    END






















GO


