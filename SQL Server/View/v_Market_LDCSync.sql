USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_Market_LDCSync]    Script Date: 08/26/2014 12:56:49 ******/
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


ALTER VIEW [dbo].[v_Market_LDCSync]
AS
    SELECT  CP_Sync_ista_ACE.SyncAccount ,
            CP_Sync_ista_ACE.SyncStartDate ,
            CP_Sync_ista_ACE.SyncEndDate ,
            'ACE' AS SyncLDC
    FROM    StreamInternal.dbo.CP_Sync_ista_ACE CP_Sync_ista_ACE
    UNION ALL
    SELECT  CP_Sync_ista_BGE_E.SyncAccount ,
            CP_Sync_ista_BGE_E.SyncStartDate ,
            CP_Sync_ista_BGE_E.SyncEndDate ,
            'BGE_E' AS SyncLDC
    FROM    StreamInternal.dbo.CP_Sync_ista_BGE_E CP_Sync_ista_BGE_E
    UNION ALL
    SELECT  CP_Sync_ista_BGE_G.SyncAccount ,
            CP_Sync_ista_BGE_G.SyncStartDate ,
            CP_Sync_ista_BGE_G.SyncEndDate ,
            'BGE_G' AS SyncLDC
    FROM    StreamInternal.dbo.CP_Sync_ista_BGE_G CP_Sync_ista_BGE_G
    UNION ALL
    SELECT  CP_Sync_ista_ConEd.SyncAccount ,
            CP_Sync_ista_ConEd.SyncStartDate ,
            CP_Sync_ista_ConEd.SyncEndDate ,
            'CONED' AS SyncLDC
    FROM    StreamInternal.dbo.CP_Sync_ista_ConEd CP_Sync_ista_ConEd
    UNION ALL
    SELECT  CP_Sync_ista_Delmarva.SyncAccount ,
            CP_Sync_ista_Delmarva.SyncStartDate ,
            CP_Sync_ista_Delmarva.SyncEndDate ,
            'DELMAR' AS SyncLDC
    FROM    StreamInternal.dbo.CP_Sync_ista_Delmarva CP_Sync_ista_Delmarva
    UNION ALL
    SELECT  CP_Sync_ista_Duquesne.SyncAccount ,
            CP_Sync_ista_Duquesne.SyncStartDate ,
            CP_Sync_ista_Duquesne.SyncEndDate ,
            'DUQ' AS SyncLDC
    FROM    StreamInternal.dbo.CP_Sync_ista_Duquesne CP_Sync_ista_Duquesne
    UNION ALL
    SELECT  CP_Sync_ista_JCPL.SyncAccount ,
            CP_Sync_ista_JCPL.SyncStartDate ,
            CP_Sync_ista_JCPL.SyncEndDate ,
            'JCPL' AS SyncLDC
    FROM    StreamInternal.dbo.CP_Sync_ista_JCPL CP_Sync_ista_JCPL
    UNION ALL
    SELECT  CP_Sync_ista_NIMO.SyncAccount ,
            CP_Sync_ista_NIMO.SyncStartDate ,
            CP_Sync_ista_NIMO.SyncEndDate ,
            'NIMO' AS SyncLDC
    FROM    StreamInternal.dbo.CP_Sync_ista_NIMO CP_Sync_ista_NIMO
    UNION ALL
    SELECT  CP_Sync_ista_NYSEG.SyncAccount ,
            CP_Sync_ista_NYSEG.SyncStartDate ,
            CP_Sync_ista_NYSEG.SyncEndDate ,
            'NYSEG' AS SyncLDC
    FROM    StreamInternal.dbo.CP_Sync_ista_NYSEG CP_Sync_ista_NYSEG
    UNION ALL
    SELECT  CP_Sync_ista_PECO.SyncAccount ,
            CP_Sync_ista_PECO.SyncStartDate ,
            CP_Sync_ista_PECO.SyncEndDate ,
            'PECO' AS SyncLDC
    FROM    StreamInternal.dbo.CP_Sync_ista_PECO CP_Sync_ista_PECO
    UNION ALL
    SELECT  CP_Sync_ista_PENELEC.SyncAccount ,
            CP_Sync_ista_PENELEC.SyncStartDate ,
            CP_Sync_ista_PENELEC.SyncEndDate ,
            'PENELEC' AS SyncLDC
    FROM    StreamInternal.dbo.CP_Sync_ista_PENELEC CP_Sync_ista_PENELEC
    UNION ALL
    SELECT  CP_Sync_ista_PEPCODC.SyncAccount ,
            CP_Sync_ista_PEPCODC.SyncStartDate ,
            CP_Sync_ista_PEPCODC.SyncEndDate ,
            'PEPCO' AS SyncLDC
    FROM    StreamInternal.dbo.CP_Sync_ista_PEPCODC CP_Sync_ista_PEPCODC
    UNION ALL
    SELECT  CP_Sync_ista_RGE.SyncAccount ,
            CP_Sync_ista_RGE.SyncStartDate ,
            CP_Sync_ista_RGE.SyncEndDate ,
            'RGE' AS SyncLDC
    FROM    StreamInternal.dbo.CP_Sync_ista_RGE CP_Sync_ista_RGE
    UNION ALL
    SELECT  CP_Sync_ista_WESTPENN.SyncAccount ,
            CP_Sync_ista_WESTPENN.SyncStartDate ,
            CP_Sync_ista_WESTPENN.SyncEndDate ,
            'WESTPENN' AS SyncLDC
    FROM    StreamInternal.dbo.CP_Sync_ista_WESTPENN CP_Sync_ista_WESTPENN
GO


