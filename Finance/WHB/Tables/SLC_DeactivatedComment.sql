CREATE TABLE [WHB].[SLC_DeactivatedComment] (
    [SLC_DeactivatedCommentID] INT          IDENTITY (1, 1) NOT NULL,
    [LikeString]               VARCHAR (30) NOT NULL,
    [LikePriority]             INT          NOT NULL,
    CONSTRAINT [PK_SLC_DeactivatedCommentID] PRIMARY KEY CLUSTERED ([SLC_DeactivatedCommentID] ASC) WITH (FILLFACTOR = 90)
);

