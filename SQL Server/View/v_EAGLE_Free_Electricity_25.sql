USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_EAGLE_Free_Electricity_25]    Script Date: 08/26/2014 13:49:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
						
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/

CREATE VIEW [dbo].[v_EAGLE_Free_Electricity_25]
AS
    SELECT  'Free Electricity 25' AS Program_Name ,
            td.[IA Number] AS IA_Number ,
            td.Name_First + ' ' + td.Name_Last AS IA_Name ,
            fe.CustNumber AS Customer_Count ,
            tc.[Customer Number] AS Customer_Number ,
            tc.Name_First + ' ' + tc.Name_Last AS Customer_Name ,
            tc.[App Date] AS App_Date ,
            tc.DstatusDesc AS Status_Desc ,
            'Electric' AS Premise_Type ,
            td.[Primary Email] AS Primary_Email ,
            td.[Primary Phone] AS Primary_Phone ,
            td.[Home Phone] AS Home_Phone ,
            td.[Cell Phone] AS Mobile_Phone ,
            td.[Billing City] AS City ,
            td.[Billing State] AS State ,
            td.[Billing Zip] AS Zip
    FROM    EAGLE.dbo.tblAssociatesAndHomesites td WITH ( NOLOCK )
    INNER JOIN ( SELECT ADcode
                 FROM   StreamInternal.dbo.v_EAGLE_HighwayElect WITH ( NOLOCK )
                 GROUP BY ADcode
                 HAVING MAX(CustNumber) > 4
                        AND MAX(CustNumber) < 10
               ) st ON st.ADcode = td.[IA Number]
    INNER JOIN EAGLE.dbo.tblCustomers tc WITH ( NOLOCK ) ON tc.[Sponsor Number] = td.[IA Number]
                                                            AND LEFT(tc.[Customer Number] ,
                                                              1) = 'C'
                                                            AND tc.DStatusDesc IN (
                                                            'PreVerify' ,
                                                            'Pending' ,
                                                            'Active' )
    INNER JOIN StreamInternal.dbo.v_EAGLE_HighwayElect fe WITH ( NOLOCK ) ON fe.Cdcode = tc.[Customer Number]
    WHERE   tc.[App Date] > '2014-02-21 00:00:00.000'
            AND td.DStatusDesc = 'Active'
            AND td.Type = 'D'
            AND td.[IA Number] NOT IN (
            SELECT DISTINCT
                    [IA_Number]
            FROM    dbo.v_EAGLE_Free_Electricity_100 )
            AND td.[IA Number] NOT IN (
            SELECT DISTINCT
                    [IA_Number]
            FROM    dbo.v_EAGLE_Free_Electricity_100_Ignition )





GO


