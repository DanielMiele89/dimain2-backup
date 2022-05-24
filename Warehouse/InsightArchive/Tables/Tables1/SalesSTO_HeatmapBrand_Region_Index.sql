﻿CREATE TABLE [InsightArchive].[SalesSTO_HeatmapBrand_Region_Index] (
    [brandid]        INT          NULL,
    [Region]         VARCHAR (50) NULL,
    [Combo_Spenders] INT          NULL,
    [Combo_Spend]    MONEY        NULL,
    [Combo_Volume]   INT          NULL,
    [Base_spenders]  INT          NULL,
    [Base_Volume]    INT          NULL,
    [Base_spend]     MONEY        NULL,
    [RR_combo]       REAL         NULL,
    [RR_Base]        REAL         NULL,
    [Index_RR]       REAL         NULL,
    [SPC_Base]       REAL         NULL,
    [SPC_Combo]      REAL         NULL,
    [Index_SPC]      REAL         NULL
);

