CREATE TABLE [Relational].[Control_Unstratified] (
    [id]        INT  IDENTITY (1, 1) NOT NULL,
    [CinID]     INT  NULL,
    [FanID]     INT  NULL,
    [StartDate] DATE NULL,
    [EndDate]   DATE NULL,
    [ClubID]    INT  NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [idx_Control]
    ON [Relational].[Control_Unstratified]([CinID] ASC, [StartDate] ASC, [EndDate] ASC);

