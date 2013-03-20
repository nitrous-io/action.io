# Behave as Coach but dont actually fire request
class NullCoach < Coach
  def self.get(*args); end
  def self.put(*args); end
  def self.post(*args); end
  def self.delete(*args); end
  def render(*args); true; end
end
