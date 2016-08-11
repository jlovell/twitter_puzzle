require 'awesome_print'

class Parser
  def self.connections_for(tweet)
    mentions = tweet.scan(/(?<=@)\w+/)
    mentions.empty? ? {} : { tweet[/^\w+/] => mentions } # { 'duncan' => ["@bob", "@carl"]}
  end
end

class Puzzle
  attr_reader :tweets

  def initialize(filename)
    @tweets = File.readlines(filename)
  end

  # {
  #   'duncan' => [ %w(bob emily farid), %w(alberta christine) ]
  #   'emily' => [ %w(farid), %w(alberta christine) ]
  # }
  def solve2
    results = {}
    people.each do |person|
      first_order = connections_for(person)
      second_order = first_order.flat_map { |person2| mutual_mentions[person2] }.uniq - first_order - [person]
      third_order = second_order.flat_map { |person3| mutual_mentions[person3] }.uniq - second_order - first_order - [person]
      results[person] = [ first_order, second_order, third_order ].reject(&:empty?)
    end
    results
  end

  def solve
    mutual_mentions.inject({}) do |result, (person, connections)|
      result[person] = [connections]
      last_order = connections
      loop do
        this_order = last_order.flat_map { |mentioned_person| mutual_mentions[mentioned_person] }.uniq - result[person].flatten - [person]

        break if this_order.empty?
        result[person] << this_order
        last_order = this_order
      end
      result
    end
  end

  def connections_for(person)
    mutual_mentions[person]
  end

  def mutual_mentions
    @mutual_mentions ||= begin
      mention_data = tweets.inject({}) do |overall, line|
        connections = Parser.connections_for(line)
        overall.merge(connections) do |tweeter, original, additional|
          (original + additional).uniq
        end
      end

      mutuals = {}
      mention_data.each do |tweeter, mentions|
        mutuals[tweeter] = mentions.select do |mention|
          mention_data[mention] && mention_data[mention].include?(tweeter)
        end.sort
      end
      mutuals
    end
  end

  def people
    @people ||= mutual_mentions.keys
  end
end

class Output
  def self.print(hash)
    hash.each do |person, orders|
      puts person
      puts orders.map { |order| order.join(', ') }
      puts
    end
  end
end

Output.print Puzzle.new('complex.txt').solve
ap Puzzle.new('complex.txt').solve
