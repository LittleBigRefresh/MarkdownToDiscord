using Discord;
using Discord.Rest;
using MarkdownToDiscord;
using MarkdownToDiscord.Elements;

string? mdPath = Environment.GetEnvironmentVariable("MARKDOWN_FILES_DIR");
string? token = Environment.GetEnvironmentVariable("DISCORD_TOKEN");

if (token == null) throw new InvalidOperationException("Cannot proceed without a Discord token");
if (mdPath == null) throw new InvalidOperationException("Cannot proceed without a markdown directory");

string? gitModified = Environment.GetEnvironmentVariable("M2D_GIT_MODIFIED");

string[]? gitFiles = null;
if (gitModified != null)
{
    Console.WriteLine("Git modified data is available!");
    gitFiles = gitModified.Split('\n', ' ')
        .Where(s => !string.IsNullOrWhiteSpace(s))
        .Select(Path.GetFullPath)
        .ToArray();
}

string[] files = Directory.GetFiles(mdPath);

async Task PostMarkdownFile(IMessageChannel channel, MarkdownParser parser, HttpClient httpClient)
{
    string buffer = string.Empty;
    foreach (IMarkdownElement element in parser.Parse())
    {
        switch (element)
        {
            case HeaderMarkdownElement headerElement:
                if (!string.IsNullOrWhiteSpace(buffer)) await channel.SendMessageAsync(buffer);
                buffer = $"**{headerElement.Text}**\n";
                break;
            case TextMarkdownElement textElement:
                buffer += textElement.Text + '\n';
                break;
            case ImageMarkdownElement imageElement:
                Stream stream = await httpClient.GetStreamAsync(imageElement.Link);
                FileAttachment attachment = new(stream, "image.png", imageElement.AltText);
                
                // it's okay to not check for length here, we're free to send attachments with no message body
                await channel.SendFileAsync(attachment, buffer);
                buffer = string.Empty;
                break;
        }
    }

    if (!string.IsNullOrWhiteSpace(buffer))
    {
        await channel.SendMessageAsync(buffer.TrimEnd());
    }
}

DiscordRestClient client = new(new DiscordRestConfig
{
    LogLevel = LogSeverity.Debug,
});

#pragma warning disable CS1998
client.Log += async message => Console.WriteLine(message);
#pragma warning restore CS1998

await client.LoginAsync(TokenType.Bot, token);

using HttpClient httpClient = new();
httpClient.DefaultRequestHeaders.Add("Accept", "image/*");

foreach (string file in files)
{
    if(!file.EndsWith(".md")) continue;

    if (gitFiles != null && !gitFiles.Contains(file))
    {
        Console.WriteLine($"File {file} was not modified by git; skipping.");
        continue;
    }
    
    Console.WriteLine("Processing file " + file);
    
    List<string> lines = (await File.ReadAllLinesAsync(file)).ToList();
    MarkdownParser parser = new(lines);
    MarkdownSettings markdownSettings = parser.ParseSettings();

    IChannel? channel = await client.GetChannelAsync(markdownSettings.ChannelId);
    if (channel == null) throw new InvalidOperationException("Could not find channel by id {id}");

    if (channel is IMessageChannel messageChannel)
    {
        if (markdownSettings.ShouldDeleteExistingContents)
        {
            await foreach (IReadOnlyCollection<IMessage> messages in messageChannel.GetMessagesAsync(50))
            foreach (IMessage message in messages)
                await message.DeleteAsync();
        }

        await PostMarkdownFile(messageChannel, parser, httpClient);
    }
}

await client.LogoutAsync();