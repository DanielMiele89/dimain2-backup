﻿CREATE TABLE [Prototype].[MVP_BrandList] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [BrandID]       INT          NOT NULL,
    [BrandName]     VARCHAR (50) NOT NULL,
    [AcquireLength] INT          NOT NULL,
    [LapsedLength]  INT          NOT NULL,
    [Override]      FLOAT (53)   NULL,
    [IsPartner]     BIT          NOT NULL,
    [StartDate]     DATE         NOT NULL,
    [EndDate]       DATE         NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [cix_BrandID]
    ON [Prototype].[MVP_BrandList]([BrandID] ASC)
    INCLUDE([EndDate]);

