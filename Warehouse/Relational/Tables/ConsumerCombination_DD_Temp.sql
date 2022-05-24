CREATE TABLE [Relational].[ConsumerCombination_DD_Temp] (
    [ConsumerCombination_DirectDebitID] INT          IDENTITY (1, 1) NOT NULL,
    [OIN]                               INT          NOT NULL,
    [Narrative_RBS]                     VARCHAR (50) NOT NULL,
    [BrandID]                           SMALLINT     NOT NULL
);

