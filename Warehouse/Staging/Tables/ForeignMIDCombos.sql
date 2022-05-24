CREATE TABLE [Staging].[ForeignMIDCombos] (
    [ReviewID]       INT          NOT NULL,
    [Narrative]      VARCHAR (50) NOT NULL,
    [IsHighVariance] BIT          NOT NULL,
    PRIMARY KEY CLUSTERED ([ReviewID] ASC)
);

