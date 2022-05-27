CREATE TABLE [InsightArchive].[ProbaTest] (
    [id]               INT          IDENTITY (1, 1) NOT NULL,
    [FanID]            VARCHAR (50) NULL,
    [MonthDate]        VARCHAR (50) NULL,
    [IsTargetSpender]  VARCHAR (50) NULL,
    [ModelProbability] FLOAT (53)   NOT NULL,
    [TargetSpender]    INT          DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [InsightArchive].[ProbaTest]([ModelProbability] ASC, [TargetSpender] ASC) WITH (FILLFACTOR = 80);

