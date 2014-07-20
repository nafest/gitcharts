require 'optparse'

class Commit
  attr_accessor :id, :author

  def initialize(id, author)
    @id = id
    @author = author
  end
end

class Author
  attr_accessor :lines_added, :lines_removed, :name

  def initialize(name)
    @name = name
    @lines_added = 0
    @lines_removed = 0
  end
end

class AuthorList
  def initialize()
    @authors = []
  end

  def add(author)
    @authors << author
  end

  def get(name)
    @authors.each do |author|
      return author if author.name == name
    end
    return nil
  end
end


options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: gitcharts.rb [options] path-to-git-repo"
end.parse!

path = ARGV.pop

raise "No repository specified" unless path

# change directory to git repository
Dir.chdir(path) do
  commits = []
  author_list = AuthorList.new
  system "git status"

  # collect all commits (on the current branch)
  output = `git --no-pager log --pretty="tformat:%H %an"`
  output.split("\n").each do |line|
    splitted = line.split (" ")
    id = splitted[0]
    author = splitted[1..-1].join(" ")
    commits << Commit.new(id,author)

    # add author to the list of authors as long as it is not already present
    author_list.add(Author.new(author)) unless author_list.get(author)
  end

  # loop over all commits and add the shortstats to the authors
  commits.each do |commit|
    cmd = "git --no-pager log  -1 --oneline --shortstat #{commit.id}"
    output = `#{cmd}`
    stat_line = output.split("\n")[1]
    added = 0
    removed = 0
    if stat_line
      splitted = stat_line.split(",")

      added = splitted[1].split(" ")[0] if splitted.length > 1 
      added = added.to_i

      removed = splitted[2].split(" ")[0] if splitted.length > 2
      removed = removed.to_i
    end
    
    author_list.get(commit.author).lines_added += added
    author_list.get(commit.author).lines_removed += removed
  end

  p commits
  p author_list

  #changes = `git --no-pager log --pretty="tformat:commit:%H %an" --numstat`
end
