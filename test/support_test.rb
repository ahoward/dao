Testing Dao::Conducer do
  testing 'that dao has a root' do
    assert{ Dao.respond_to?(:root) }
    assert{ Dao.root }
  end

  testing 'that dao can build a mock controller' do
    controller = assert{ Dao.mock_controller }
    assert{ controller.url_for '/' }
  end

  testing 'that dao can mark the current_controller' do
    assert{ Dao.current_controller = Dao.mock_controller }
  end

  testing 'that dao can pre-process parameters' do
    params = Map.new( 
      'dao' => {
        'foos' => {
          'k' => 'v',
          'array.0' => '0',
          'array.1' => '1'
        },

        'bars' => {
          'a' => 'b',
          'hash.k' => 'v'
        }
      }
    )

    assert{ Dao.normalize_parameters(params) }
    assert{ params[:dao] = :normalized }

    assert{ params[:foos].is_a?(Hash) }
    assert{ params[:foos][:k] == 'v' }
    assert{ params[:foos][:array] == %w( 0 1 ) }

    assert{ params[:bars].is_a?(Hash) }
    assert{ params[:bars][:a] == 'b' }
    assert{ params[:bars][:hash] == {'k' => 'v'} }
  end
end


BEGIN {
  testdir = File.dirname(File.expand_path(__FILE__))
  rootdir = File.dirname(testdir)
  libdir = File.join(rootdir, 'lib')
  require File.join(libdir, 'dao')
  require File.join(testdir, 'testing')
}
