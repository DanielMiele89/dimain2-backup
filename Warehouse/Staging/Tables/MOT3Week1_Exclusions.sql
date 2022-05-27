CREATE TABLE [Staging].[MOT3Week1_Exclusions] (
    [ExclusionID] INT  IDENTITY (1, 1) NOT NULL,
    [FanID]       INT  NOT NULL,
    [AddedDate]   DATE NOT NULL,
    PRIMARY KEY CLUSTERED ([ExclusionID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_Fan]
    ON [Staging].[MOT3Week1_Exclusions]([FanID] ASC, [AddedDate] ASC);

