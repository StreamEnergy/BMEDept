USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_FEA_Energy]    Script Date: 08/26/2014 13:52:06 ******/
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

CREATE VIEW [dbo].[v_FEA_Energy]
AS
    SELECT  *
    FROM    [StreamInternal].[dbo].[v_EAGLE_Free_Electricity_100]
    UNION
    SELECT  *
    FROM    [StreamInternal].[dbo].[v_EAGLE_Free_Electricity_100_Ignition]
    UNION
    SELECT  *
    FROM    [StreamInternal].[dbo].[v_EAGLE_Free_Electricity_50]
    UNION
    SELECT  *
    FROM    [StreamInternal].[dbo].[v_EAGLE_Free_Electricity_25]
    UNION
    SELECT  *
    FROM    [StreamInternal].[dbo].[v_EAGLE_Free_Gas_100]
    UNION
    SELECT  *
    FROM    [StreamInternal].[dbo].[v_EAGLE_Free_Gas_100_Ignition]
    UNION
    SELECT  *
    FROM    [StreamInternal].[dbo].[v_EAGLE_Free_Gas_50]
    UNION
    SELECT  *
    FROM    [StreamInternal].[dbo].[v_EAGLE_Free_Gas_25]


GO


