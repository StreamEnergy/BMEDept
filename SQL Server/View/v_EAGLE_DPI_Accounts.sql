USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_EAGLE_DPI_Accounts]    Script Date: 08/26/2014 09:44:37 ******/
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

ALTER VIEW [dbo].[v_EAGLE_DPI_Accounts]
AS
    ( SELECT    'Free Electricity 12' AS Program_Name ,
                td.[IA Number] AS IA_Number ,
                td.Name_First + ' ' + td.Name_Last AS IA_Name ,
                fe.CustNumber AS Customer_Count ,
                tc.[Customer Number] AS Customer_Number ,
                tc.Name_First + ' ' + tc.Name_Last AS Customer_Name ,
                tc.[App Date] AS App_Date ,
                tc.DstatusDesc AS Status_Desc ,
                'Electric' AS Premise_Type
      FROM      EAGLE.dbo.tblAssociatesAndHomesites td WITH ( NOLOCK )
      INNER JOIN ( SELECT   ADcode
                   FROM     StreamInternal.dbo.v_EAGLE_FreeElect WITH ( NOLOCK )
                   GROUP BY ADcode
                   HAVING   MAX(CustNumber) > 11
                 ) st ON st.ADcode = td.[IA Number]
      INNER JOIN EAGLE.dbo.tblCustomers tc WITH ( NOLOCK ) ON tc.[Sponsor Number] = td.[IA Number]
                                                              AND LEFT(tc.[Customer Number] ,
                                                              1) = 'C'
                                                              AND tc.DStatusDesc IN (
                                                              'PreVerify' ,
                                                              'Pending' ,
                                                              'Active' )
      INNER JOIN StreamInternal.dbo.v_EAGLE_FreeElect fe WITH ( NOLOCK ) ON fe.Cdcode = tc.[Customer Number]
      WHERE     tc.[App Date] > '2013-09-28'
                AND td.DStatusDesc = 'Active'
                AND td.Type = 'D' 
-- ORDER BY td.[IA Number], fe.CustNumber
    )
    UNION
    ( SELECT    'Free Gas 12' AS Program_Name ,
                td.[IA Number] AS IA_Number ,
                td.Name_First + ' ' + td.Name_Last AS IA_Name ,
                tp.CustNumber AS Customer_Count ,
                tc.[Customer Number] AS Customer_Number ,
                tc.Name_First + ' ' + tc.Name_Last AS Customer_Name ,
                tc.[App Date] AS App_Date ,
                tc.DstatusDesc AS Status_Desc ,
                'Gas' AS Premise_Type
      FROM      EAGLE.dbo.tblAssociatesAndHomesites td WITH ( NOLOCK )
      INNER JOIN ( SELECT   ADcode
                   FROM     StreamInternal.dbo.v_EAGLE_Top15Gas WITH ( NOLOCK )
                   GROUP BY ADcode
                   HAVING   MAX(CustNumber) > 11
                 ) st ON st.ADcode = td.[IA Number]
      INNER JOIN EAGLE.dbo.tblCustomers tc WITH ( NOLOCK ) ON tc.[Sponsor Number] = td.[IA Number]
                                                              AND LEFT(tc.[Customer Number] ,
                                                              1) = 'G'
                                                              AND tc.DStatusDesc IN (
                                                              'PreVerify' ,
                                                              'Pending' ,
                                                              'Active' )
      INNER JOIN StreamInternal.dbo.v_EAGLE_Top15Gas tp WITH ( NOLOCK ) ON tp.Cdcode = tc.[Customer Number]
      WHERE     tc.[App Date] > '2013-09-28'
                AND td.DStatusDesc = 'Active'
                AND td.Type = 'D' 
-- ORDER BY td.[IA Number], tp.CustNumber
    )
    UNION
    ( SELECT    'Free Electricity 10' AS Program_Name ,
                td.[IA Number] AS IA_Number ,
                td.Name_First + ' ' + td.Name_Last AS IA_Name ,
                fe.CustNumber AS Customer_Count ,
                tc.[Customer Number] AS Customer_Number ,
                tc.Name_First + ' ' + tc.Name_Last AS Customer_Name ,
                tc.[App Date] AS App_Date ,
                tc.DstatusDesc AS Status_Desc ,
                'Electric' AS Premise_Type
      FROM      EAGLE.dbo.tblAssociatesAndHomesites td WITH ( NOLOCK )
      INNER JOIN ( SELECT   ADcode
                   FROM     StreamInternal.dbo.v_EAGLE_FreeElect WITH ( NOLOCK )
                   GROUP BY ADcode
                   HAVING   MAX(CustNumber) = 10
                 ) st ON st.ADcode = td.[IA Number]
      INNER JOIN EAGLE.dbo.tblCustomers tc WITH ( NOLOCK ) ON tc.[Sponsor Number] = td.[IA Number]
                                                              AND LEFT(tc.[Customer Number] ,
                                                              1) = 'C'
                                                              AND tc.DStatusDesc IN (
                                                              'PreVerify' ,
                                                              'Pending' ,
                                                              'Active' )
      INNER JOIN StreamInternal.dbo.v_EAGLE_FreeElect fe WITH ( NOLOCK ) ON fe.Cdcode = tc.[Customer Number]
      WHERE     tc.[App Date] > '2013-09-28 00:00:00.000'
                AND td.DStatusDesc = 'Active'
                AND td.Type = 'D'				
--and	fe.CustNumber				> 11
    )
    UNION
    ( SELECT    'Free Gas 10' AS Program_Name ,
                td.[IA Number] AS IA_Number ,
                td.Name_First + ' ' + td.Name_Last AS IA_Name ,
                tp.CustNumber AS Customer_Count ,
                tc.[Customer Number] AS Customer_Number ,
                tc.Name_First + ' ' + tc.Name_Last AS Customer_Name ,
                tc.[App Date] AS App_Date ,
                tc.DstatusDesc AS Status_Desc ,
                'Gas' AS Premise_Type
      FROM      EAGLE.dbo.tblAssociatesAndHomesites td WITH ( NOLOCK )
      INNER JOIN ( SELECT   ADcode
                   FROM     StreamInternal.dbo.v_EAGLE_Top15Gas WITH ( NOLOCK )
                   GROUP BY ADcode
                   HAVING   MAX(CustNumber) = 10
                 ) st ON st.ADcode = td.[IA Number]
      INNER JOIN EAGLE.dbo.tblCustomers tc WITH ( NOLOCK ) ON tc.[Sponsor Number] = td.[IA Number]
                                                              AND LEFT(tc.[Customer Number] ,
                                                              1) = 'G'
                                                              AND tc.DStatusDesc IN (
                                                              'PreVerify' ,
                                                              'Pending' ,
                                                              'Active' )
      INNER JOIN StreamInternal.dbo.v_EAGLE_Top15Gas tp WITH ( NOLOCK ) ON tp.Cdcode = tc.[Customer Number]
      WHERE     tc.[App Date] > '2013-09-28 00:00:00.000'
                AND td.DStatusDesc = 'Active'
                AND td.Type = 'D' 
--and fe.CustNumber > 11
-- ORDER BY td.[IA Number], tp.CustNumber
    )
    UNION
    ( SELECT    'Free Electricity 5' AS Program_Name ,
                td.[IA Number] AS IA_Number ,
                td.Name_First + ' ' + td.Name_Last AS IA_Name ,
                fe.CustNumber AS Customer_Count ,
                tc.[Customer Number] AS Customer_Number ,
                tc.Name_First + ' ' + tc.Name_Last AS Customer_Name ,
                tc.[App Date] AS App_Date ,
                tc.DstatusDesc AS Status_Desc ,
                'Electric' AS Premise_Type
      FROM      EAGLE.dbo.tblAssociatesAndHomesites td WITH ( NOLOCK )
      INNER JOIN ( SELECT   ADcode
                   FROM     StreamInternal.dbo.v_EAGLE_FreeElect WITH ( NOLOCK )
                   GROUP BY ADcode
                   HAVING   MAX(CustNumber) = 5
                 ) st ON st.ADcode = td.[IA Number]
      INNER JOIN EAGLE.dbo.tblCustomers tc WITH ( NOLOCK ) ON tc.[Sponsor Number] = td.[IA Number]
                                                              AND LEFT(tc.[Customer Number] ,
                                                              1) = 'C'
                                                              AND tc.DStatusDesc IN (
                                                              'PreVerify' ,
                                                              'Pending' ,
                                                              'Active' )
      INNER JOIN StreamInternal.dbo.v_EAGLE_FreeElect fe WITH ( NOLOCK ) ON fe.Cdcode = tc.[Customer Number]
      WHERE     tc.[App Date] > '2013-09-28 00:00:00.000'
                AND td.DStatusDesc = 'Active'
                AND td.Type = 'D' 
--and fe.CustNumber > 11
    )
    UNION
    ( SELECT    'Free Gas 5' AS Program_Name ,
                td.[IA Number] AS IA_Number ,
                td.Name_First + ' ' + td.Name_Last AS IA_Name ,
                tp.CustNumber AS Customer_Count ,
                tc.[Customer Number] AS Customer_Number ,
                tc.Name_First + ' ' + tc.Name_Last AS Customer_Name ,
                tc.[App Date] AS App_Date ,
                tc.DstatusDesc AS Status_Desc ,
                'Gas' AS Premise_Type
      FROM      EAGLE.dbo.tblAssociatesAndHomesites td WITH ( NOLOCK )
      INNER JOIN ( SELECT   ADcode
                   FROM     StreamInternal.dbo.v_EAGLE_Top15Gas WITH ( NOLOCK )
                   GROUP BY ADcode
                   HAVING   MAX(CustNumber) = 5
                 ) st ON st.ADcode = td.[IA Number]
      INNER JOIN EAGLE.dbo.tblCustomers tc WITH ( NOLOCK ) ON tc.[Sponsor Number] = td.[IA Number]
                                                              AND LEFT(tc.[Customer Number] ,
                                                              1) = 'G'
                                                              AND tc.DStatusDesc IN (
                                                              'PreVerify' ,
                                                              'Pending' ,
                                                              'Active' )
      INNER JOIN StreamInternal.dbo.v_EAGLE_Top15Gas tp WITH ( NOLOCK ) ON tp.Cdcode = tc.[Customer Number]
      WHERE     tc.[App Date] > '2013-09-28 00:00:00.000'
                AND td.DStatusDesc = 'Active'
                AND td.Type = 'D' 
--and fe.CustNumber > 11
    )

 -- order by 1,2,3,4
GO


