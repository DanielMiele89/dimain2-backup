CREATE TABLE [Relational].[ConsumerCombination_DD] (
    [ConsumerCombinationID_DD] BIGINT       IDENTITY (1, 1) NOT NULL,
    [OIN]                      INT          NOT NULL,
    [Narrative_RBS]            VARCHAR (50) NULL,
    [Narrative_VF]             VARCHAR (50) NULL,
    [BrandID]                  INT          NOT NULL,
    CONSTRAINT [PK_Relational_ConsumerCombination_DD] PRIMARY KEY CLUSTERED ([ConsumerCombinationID_DD] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_BrandID]
    ON [Relational].[ConsumerCombination_DD]([BrandID] ASC)
    INCLUDE([ConsumerCombinationID_DD]) WITH (FILLFACTOR = 95);


GO
CREATE NONCLUSTERED INDEX [IX_OIN]
    ON [Relational].[ConsumerCombination_DD]([OIN] ASC)
    INCLUDE([ConsumerCombinationID_DD], [Narrative_RBS], [Narrative_VF]) WITH (FILLFACTOR = 95);

