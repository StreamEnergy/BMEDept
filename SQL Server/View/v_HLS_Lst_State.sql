USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_HLS_Lst_State]    Script Date: 08/26/2014 13:52:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
07/25/2014				Jide Akintoye						List of States contained in the  HLS Customer Data.					
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/



CREATE VIEW [dbo].[v_HLS_Lst_State]
AS
    SELECT DISTINCT
            S.StateID ,
            'StateAbbr' = H.State ,
            S.State
    FROM    dbo.HLS_Customers_Data H
    LEFT JOIN dbo.Lst_State S ON H.State = S.StateAbbr



GO


