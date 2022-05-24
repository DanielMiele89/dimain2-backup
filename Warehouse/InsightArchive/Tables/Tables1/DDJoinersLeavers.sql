﻿CREATE TABLE [InsightArchive].[DDJoinersLeavers] (
    [FirstTransactionDate] DATETIME     NULL,
    [LastTransactionDate]  DATETIME     NULL,
    [Joiners]              INT          NULL,
    [BrandName]            VARCHAR (50) NOT NULL,
    [SectorName]           VARCHAR (50) NULL
);


GO
CREATE CLUSTERED INDEX [ix_ComboID]
    ON [InsightArchive].[DDJoinersLeavers]([FirstTransactionDate] ASC);

