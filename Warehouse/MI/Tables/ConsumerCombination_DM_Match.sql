CREATE TABLE [MI].[ConsumerCombination_DM_Match] (
    [ID]                    INT      IDENTITY (1, 1) NOT NULL,
    [ConsumerCombinationID] INT      NOT NULL,
    [BrandMatchID]          INT      NOT NULL,
    [BrandID]               SMALLINT NOT NULL,
    [BrandGroupID]          TINYINT  NULL,
    CONSTRAINT [PK_MI_ConsumerCombination_DM_Match] PRIMARY KEY CLUSTERED ([ID] ASC)
);

