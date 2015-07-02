require 'spec_helper'
require 'update_draft_release'

RSpec.describe UpdateDraftRelease::Runner do
  let(:logger) { double() }
  let(:user) { double(login: 'user') }
  let(:client) { double(user: user) }
  let(:draft) { double(draft: true, name: 'draft', url: 'http://draft/', body: 'draft') }
  let(:release) { double(draft: false, name: '2015-07-02', body: 'release') }
  let(:commit) do
    double(committer: double(login: 'user'),
           commit: double(message: 'message'),
           sha: 'abc')
  end

  before do
    allow(Logger).to receive(:new).and_return(logger)
    allow(Octokit::Client).to receive(:new).and_return(client)
  end

  context 'when no valid release' do
    let(:runner) { UpdateDraftRelease::Runner.new('repo/repo') }

    it 'exit on no release' do
      allow(client).to receive(:releases).and_return([])
      expect { runner.update_draft_release }.to raise_error(SystemExit)
    end

    it 'exit on no draft release' do
      allow(client).to receive(:releases).and_return([double(draft: false)])
      expect { runner.update_draft_release }.to raise_error(SystemExit)
    end
  end

  context 'when no valid commits' do
    let(:runner) { UpdateDraftRelease::Runner.new('repo/repo') }

    before { allow(client).to receive(:releases).and_return([draft, release]) }

    it 'exit on no commits' do
      allow(client).to receive(:commits).and_return([])
      expect { runner.update_draft_release }.to raise_error(SystemExit)
    end

    it 'exit on commits already in draft' do
      allow(client).to receive(:commits).and_return([commit])
      allow(draft).to receive(:body).and_return("Message #{commit.sha}")
      expect { runner.update_draft_release }.to raise_error(SystemExit)
    end

    it 'exit on commits already in release' do
      allow(client).to receive(:commits).and_return([commit])
      allow(release).to receive(:body).and_return("Message #{commit.sha}")
      expect { runner.update_draft_release }.to raise_error(SystemExit)
    end
  end

  context 'when things go well' do
    let(:runner) { UpdateDraftRelease::Runner.new('repo/repo', { skip_confirmation: true }) }

    before do
      allow(client).to receive(:releases).and_return([release, draft, release])
      allow(client).to receive(:commits).and_return([commit])
    end

    it 'update the release' do
      expect(client).to receive(:update_release).and_return(true)
      runner.update_draft_release
    end
  end
end
