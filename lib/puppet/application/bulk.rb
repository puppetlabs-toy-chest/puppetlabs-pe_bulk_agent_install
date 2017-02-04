require 'puppet/application/face_base'

# This subcommand is implemented as a face. The definition of the application
# can be found in face/bulk.rb.
module Puppet
  class Application
    class Bulk < Puppet::Application::FaceBase
    end
  end
end
