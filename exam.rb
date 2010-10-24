#############################################################################
#############################################################################
## RUBY MENDICANT EXAM - 2011 T1 ENTRANCE EXAM
## Submitter: Jaime Iniesta (jaimeiniesta@gmail.com)
## Date: October 7th, 2010
#############################################################################
#############################################################################

require 'rubygems'
require 'fastercsv'

#
# Each student knows its name and availability for Mondays and Wednesdays
# and is able to answer about if she's able to attend a given day/hour
#
class Student
  attr_reader :name
  
  # When creating a student, store her name and availability for Monday and Wednesday
  def initialize(name, monday_hours, wednesday_hours)
    @name         = name
    @availability = {
                      :monday     => monday_hours.split(",").collect {|h| h.strip},
                      :wednesday  => wednesday_hours.split(",").collect {|h| h.strip}
                    }
  end
  
  # Tells if the student is available for a given day and hour
  def available_on?(day, hour)
    @availability[day].include?(hour)
  end
  
  # Tells how many meetings can attend for a given Monday and Wednesday hour proposal
  # Can be 0, 1, or 2
  def score_for_pair(monday_hour, wednesday_hour)
    score  = 0
    score += 1 if available_on?(:monday, monday_hour)
    score += 1 if available_on?(:wednesday, wednesday_hour)
    score
  end
  
  # Tells if the student can attend at least one day for a given Monday and Wednesday
  # hour proposal. It can be 0 or 1
  def attendability_for_pair(monday_hour, wednesday_hour)
    score_for_pair(monday_hour, wednesday_hour) == 0 ? 0 : 1
  end
end


#
# A planner reads a CSV, builds a collection of students and hours
# and is able to calculate the best starting times to maximize attendability
# 
# To achieve the first requirement, we measure the attendabilities for each
# combination of Monday and Wednesday hours, as the number of students that
# can attend at least one of the meetings.
#
# To achieve the second requirement, we do a similar measure for the scores
# being 0, 1, or 2 for each student meaning the number of meetings that will
# be able to attend for each given combination of Monday and Wednesday times.
#
# We then pick the highest attainability, and for those combinations meeting it,
# we choose the one with the best total score to maximize it
#
class Planner
  
  # When creating a new planner, build a collection of students with their names
  # and personal availabilities, and a collection of daily slots with the possible
  # starting times for Monday and Wednesday
  def initialize(csv)
    @students = []
    @daily_slots = {:monday => [], :wednesday => []}
    FasterCSV.foreach(csv, :headers => true) do |row|
      @students                 << Student.new(row[0], row[1], row[2])
      @daily_slots[:monday]     << row[1].split(",").collect {|h| h.strip}
      @daily_slots[:wednesday]  << row[2].split(",").collect {|h| h.strip}
    end
    @daily_slots[:monday].flatten!.uniq!
    @daily_slots[:wednesday].flatten!.uniq!
  end
  
  # Returns a collection of students available for a given day and hour
  def who_is_available_on(day, hour)
    @students.select {|s| s.available_on?(day, hour)}
  end
  
  # Returns the number of students who are available for a given day and hour
  def how_many_available_on(day, hour)
    who_is_available_on(day, hour).size
  end
  
  # Returns the sum of student scores for all students for that given combination
  # of Monday hour and Wednesday hour
  def score_for_pair(monday_hour, wednesday_hour)
    @students.inject(0) {|sum, student| sum + student.score_for_pair(monday_hour, wednesday_hour)}
  end
  
  # Returns the sum of attendabilities for all students for that given combination
  # of Monday hour and Wednesday hour
  def attendability_for_pair(monday_hour, wednesday_hour)
    @students.inject(0) {|sum, student| sum + student.attendability_for_pair(monday_hour, wednesday_hour)}
  end
  
  # Loops through each possible combination of Monday and Wednesday hours
  # and calculates the score and attendability for each combination
  def calculate_scores_and_attendabilities
    @scores = {}
    @attendabilities = {}
    
    @daily_slots[:monday].each do |monday_hour|
      @daily_slots[:wednesday].each do |wednesday_hour|
        @scores[[monday_hour, wednesday_hour]] = score_for_pair(monday_hour, wednesday_hour)
        @attendabilities[[monday_hour, wednesday_hour]] = attendability_for_pair(monday_hour, wednesday_hour)
      end
    end
  end
  
  # Calculates attendabilities and scores for each combination, takes the ones
  # with the highest attendability and picks from them the one with the highest score,
  # and finally produces the two text files with the rosters
  def plan
    calculate_scores_and_attendabilities
    
    highest_attendability_value = @attendabilities.sort {|a,b| a[1] <=> b[1]}.reverse[0][1]
    best_attendabilities = @attendabilities.to_a.select {|a| (a[1] == highest_attendability_value)}
    pairs_with_best_attendabilities = best_attendabilities.collect {|b| b[0]}
    best_scores = @scores.to_a.select {|s| pairs_with_best_attendabilities.include?(s[0])}.sort {|a,b| a[1] <=> b[1]}.reverse
       
    produce_roster(:monday, best_scores[0][0][0])
    produce_roster(:wednesday, best_scores[0][0][1])
  end
  
  # Writes a file with the roster for a given day and hour
  def produce_roster(day, hour)
    File.open("#{day.to_s}-roster.txt", "w") do |file|
      file.puts "#{hour}\n\n"
      who_is_available_on(day, hour).collect {|student| student.name}.sort.collect {|name| file.puts name}
    end
    
    puts "#{day.to_s.capitalize} roster saved as #{day.to_s}-roster.txt"
  end
end
#############################################################################

# Run it!
planner = Planner.new('student_availability.csv')
planner.plan