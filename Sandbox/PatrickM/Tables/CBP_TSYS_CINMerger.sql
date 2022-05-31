CREATE TABLE [PatrickM].[CBP_TSYS_CINMerger] (
    [SecondaryFanID]      INT           NOT NULL,
    [MasterFanID]         INT           NOT NULL,
    [DateMatchIdentified] DATETIME2 (3) NOT NULL,
    [DateMatchConfirmed]  DATETIME2 (3) NULL,
    [DateMerged]          DATETIME2 (3) NULL
);

