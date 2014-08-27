USE [StreamInternal]
GO

/****** Object:  View [dbo].[vLDCLookup]    Script Date: 08/26/2014 15:15:55 ******/
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



CREATE VIEW [dbo].[vLDCLookup]
AS
    SELECT  *
    FROM    stream.dbo.LDCLookup



GO


