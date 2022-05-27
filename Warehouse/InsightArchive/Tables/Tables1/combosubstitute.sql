CREATE TABLE [InsightArchive].[combosubstitute] (
    [consumerCombinationID] INT NOT NULL,
    [ComboSubstituteID]     INT NOT NULL,
    [KeepThis]              BIT DEFAULT ((0)) NULL,
    PRIMARY KEY CLUSTERED ([consumerCombinationID] ASC)
);

