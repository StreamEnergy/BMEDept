USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_HLS_Package_View]    Script Date: 08/26/2014 14:19:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
07/25/2014				Jide Akintoye						List of Packages contained in the  HLS Customer Data.					
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/



CREATE VIEW [dbo].[v_HLS_Package_View]
AS
    SELECT  ROW_NUMBER() OVER ( ORDER BY ProductCode ) AS PackageID ,
            VendorCustomerNumber ,
            ProductCode ,
            CASE WHEN ProductCode IN ( 'seidcrit01' , 'seidcrit02' )
                 THEN 'Platinum'
	 --WHEN ProductCode IN ('seidcr01', 'seidcr02', 'seidit02', 'secrit02')THEN 'Gold'
	 --WHEN ProductCode IN ('secr01', 'secr02', 'seid01', 'seid02','seit01', 'seit02')THEN 'Silver'
                 ELSE NULL
            END AS 'Package'
    FROM    dbo.HLS_Customers_Data H
    UNION
    SELECT  ROW_NUMBER() OVER ( ORDER BY ProductCode ) AS PackageID ,
            VendorCustomerNumber ,
            ProductCode ,
            CASE --WHEN ProductCode IN ('seidcrit01', 'seidcrit02') THEN 'Platinum'
                 WHEN ProductCode IN ( 'seidcr01' , 'seidcr02' , 'seidit02' , 'secrit01','seidit01',
                                       'secrit02' ) THEN 'Gold'
	 --WHEN ProductCode IN ('secr01', 'secr02', 'seid01', 'seid02','seit01', 'seit02')THEN 'Silver'
                 ELSE NULL
            END AS 'Package'
    FROM    dbo.HLS_Customers_Data H
    UNION
    SELECT  ROW_NUMBER() OVER ( ORDER BY ProductCode ) AS PackageID ,
            VendorCustomerNumber ,
            ProductCode ,
            CASE --WHEN ProductCode IN ('seidcrit01', 'seidcrit02') THEN 'Platinum'
	 --WHEN ProductCode IN ('seidcr01', 'seidcr02', 'seidit02', 'secrit02')THEN 'Gold'
                 WHEN ProductCode IN ( 'secr01' , 'secr02' , 'seid01' ,
                                       'seid02' , 'seit01' , 'seit02' )
                 THEN 'Silver'
                 ELSE NULL
            END AS 'Package'
    FROM    dbo.HLS_Customers_Data H






GO


