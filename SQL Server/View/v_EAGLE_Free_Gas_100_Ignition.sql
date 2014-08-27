USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_EAGLE_Free_Gas_100_Ignition]    Script Date: 08/26/2014 13:50:34 ******/
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

CREATE VIEW [dbo].[v_EAGLE_Free_Gas_100_Ignition]
AS
    SELECT  'Free Gas 100 Ignition' AS Program_Name ,
            td.[IA Number] AS IA_Number ,
            td.Name_First + ' ' + td.Name_Last AS IA_Name ,
            tp.CustNumber AS Customer_Count ,
            tc.[Customer Number] AS Customer_Number ,
            tc.Name_First + ' ' + tc.Name_Last AS Customer_Name ,
            tc.[App Date] AS App_Date ,
            tc.DstatusDesc AS Status_Desc ,
            'Gas' AS Premise_Type ,
            td.[Primary Email] AS Primary_Email ,
            td.[Primary Phone] AS Primary_Phone ,
            td.[Home Phone] AS Home_Phone ,
            td.[Cell Phone] AS Mobile_Phone ,
            td.[Billing City] AS City ,
            td.[Billing State] AS State ,
            td.[Billing Zip] AS Zip
    FROM    EAGLE.dbo.tblAssociatesAndHomesites td WITH ( NOLOCK )
    INNER JOIN ( SELECT ADcode
                 FROM   StreamInternal.dbo.v_EAGLE_FreeGas WITH ( NOLOCK )
                 GROUP BY ADcode
                 HAVING MAX(CustNumber) > 11
                        AND MAX(CustNumber) < 15
               ) st ON st.ADcode = td.[IA Number]
    INNER JOIN EAGLE.dbo.tblCustomers tc WITH ( NOLOCK ) ON tc.[Sponsor Number] = td.[IA Number]
                                                            AND LEFT(tc.[Customer Number] ,
                                                              1) = 'G'
                                                            AND tc.DStatusDesc IN (
                                                            'PreVerify' ,
                                                            'Pending' ,
                                                            'Active' )
    INNER JOIN StreamInternal.dbo.v_EAGLE_FreeGas tp WITH ( NOLOCK ) ON tp.Cdcode = tc.[Customer Number]
    INNER JOIN Eagle.dbo.tblConferences con ON con.[IA Number] = td.[IA Number]
                                               AND con.Conference = 'Ignition 2014'
    WHERE   tc.[App Date] > '2013-09-28'
            AND td.DStatusDesc = 'Active'
            AND td.Type = 'D' 
-- AND		td.[IA Number]					NOT IN (SELECT distinct [IA_Number] from dbo.v_EAGLE_Free_Gas_100)








GO


