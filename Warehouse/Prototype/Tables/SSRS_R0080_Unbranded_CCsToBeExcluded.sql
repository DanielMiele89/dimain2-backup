CREATE TABLE [Prototype].[SSRS_R0080_Unbranded_CCsToBeExcluded] (
    [ConsumerCombinationID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [IDX_CCID]
    ON [Prototype].[SSRS_R0080_Unbranded_CCsToBeExcluded]([ConsumerCombinationID] ASC);

