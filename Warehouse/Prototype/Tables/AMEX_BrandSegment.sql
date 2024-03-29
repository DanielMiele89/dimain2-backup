﻿CREATE TABLE [Prototype].[AMEX_BrandSegment] (
    [BrandID]                SMALLINT         NULL,
    [BrandName]              VARCHAR (50)     NULL,
    [Segment]                VARCHAR (50)     NULL,
    [Base]                   INT              NULL,
    [Brand_Spend]            MONEY            NULL,
    [Brand_Trans]            INT              NULL,
    [Brand_Spenders]         INT              NULL,
    [Brand_ATV]              NUMERIC (33, 16) NULL,
    [Brand_ATF]              NUMERIC (33, 16) NULL,
    [Brand_SPS]              NUMERIC (33, 16) NULL,
    [Brand_RR]               NUMERIC (33, 16) NULL,
    [Sector_Spend]           MONEY            NULL,
    [Sector_Trans]           INT              NULL,
    [Sector_Spenders]        INT              NULL,
    [Sector_ATV]             NUMERIC (33, 16) NULL,
    [Sector_ATF]             NUMERIC (33, 16) NULL,
    [Sector_SPS]             NUMERIC (33, 16) NULL,
    [Sector_RR]              NUMERIC (33, 16) NULL,
    [InStore_Brand_Spend]    MONEY            NULL,
    [InStore_Brand_Trans]    INT              NULL,
    [InStore_Brand_Spenders] INT              NULL,
    [InStore_Brand_ATV]      NUMERIC (33, 16) NULL,
    [InStore_Brand_ATF]      NUMERIC (33, 16) NULL,
    [InStore_Brand_SPS]      NUMERIC (33, 16) NULL,
    [InStore_Brand_RR]       NUMERIC (33, 16) NULL
);

