using System.Diagnostics.Contracts;
using System.Text.RegularExpressions;
using MarkdownToDiscord.Elements;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;

namespace MarkdownToDiscord;

public partial class MarkdownParser
{
    public MarkdownParser(List<string> lines)
    {
        this._lines = lines;
    }

    [GeneratedRegex(@"\[([^\]]+)\]\(([^)]+)\)")]
    private static partial Regex LinkRegex();
    
    [GeneratedRegex(@"!\[([^\]]+)\]\(([^)]+)\)")]
    private static partial Regex ImageRegex();

    private static readonly IDeserializer Deserializer = new DeserializerBuilder()
        .WithNamingConvention(CamelCaseNamingConvention.Instance)
        .Build();

    private readonly List<string> _lines;
    private int _linesToSkip = 0;

    [Pure]
    public IEnumerable<IMarkdownElement> Parse()
    {
        foreach (string lineImmutable in this._lines.Skip(this._linesToSkip))
        {
            string line = lineImmutable;
            IMarkdownElement? element = null;
    
            foreach (Match match in ImageRegex().Matches(line))
            {
                string altText = match.Groups[1].Value;
                string linkText = match.Groups[2].Value;
        
                element = new ImageMarkdownElement(linkText, altText);
            }

            if (line.StartsWith("# ")) 
                element = new HeaderMarkdownElement(line.Substring(2));

            if(element != null)
            {
                yield return element;
                continue;
            }

            foreach (Match match in LinkRegex().Matches(line))
            {
                string altText = match.Groups[1].Value;
                string linkText = match.Groups[2].Value;
        
                line = line.Replace(match.Groups[0].Value, $"{altText}: <{linkText}>");
            }

            element = new TextMarkdownElement(line);
            yield return element;
        }
    }
    
    public FrontMatter ParseFrontMatter()
    {
        int frontMatterIndex = this._lines.IndexOf("---", 1);
        this._linesToSkip = frontMatterIndex + 1;
        
        string frontMatter = string.Join('\n', this._lines.Skip(1).Take(frontMatterIndex - 1));
        return Deserializer.Deserialize<FrontMatter>(frontMatter);
    }
}